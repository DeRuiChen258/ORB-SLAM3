// Barron General Adaptive Robust Kernel implementation for g2o
// See robust_kernel_barron.h for documentation.

#include "robust_kernel_barron.h"
#include "robust_kernel_factory.h"

#include <cmath>
#include <algorithm>
#include <stdexcept>

namespace g2o {

// --- Static member definitions ---
std::vector<double> RobustKernelBarron::sLogZTable;
bool RobustKernelBarron::sTableInitialized = false;

// ---------------------------------------------------------------------------
// Constructor
// ---------------------------------------------------------------------------
RobustKernelBarron::RobustKernelBarron()
    : _alpha(2.0), _c(1.0), _csqr(1.0) {}

void RobustKernelBarron::setAlpha(double alpha) {
    _alpha = std::min(alpha, 2.0);
}

void RobustKernelBarron::setC(double c) {
    _c    = c;
    _csqr = c * c;
}

// ---------------------------------------------------------------------------
// Unnormalized Barron loss — paper convention (c = 1), input r2 = raw x²
// Used for the log-Z table and alpha estimation.
// ρ_raw(r2; α) = |α−2|/α · [(r2/|α−2| + 1)^(α/2) − 1]
// ---------------------------------------------------------------------------
double RobustKernelBarron::barronLossRaw(double r2, double alpha) {
    if (std::abs(alpha - 2.0) < 1e-6) {
        return r2 / 2.0;
    }
    if (std::abs(alpha) < 1e-6) {
        return std::log(r2 / 2.0 + 1.0);
    }
    if (alpha < -50.0) {
        return 1.0 - std::exp(-r2 / 2.0);
    }
    const double abs_a2 = std::abs(alpha - 2.0);   // = 2 − α  for α < 2
    const double u      = r2 / abs_a2 + 1.0;
    // Guard against negative base in pow (can't happen since u ≥ 1, but be safe)
    const double upow   = std::pow(std::max(u, 1e-300), alpha / 2.0);
    return abs_a2 / alpha * (upow - 1.0);
}

// ---------------------------------------------------------------------------
// Build log Z lookup table at first use.
// Z(α) = ∫_{−X_MAX}^{X_MAX} exp(−ρ_raw(x²; α)) dx
// Midpoint rule over [0, X_MAX], doubled for symmetry.
// ---------------------------------------------------------------------------
void RobustKernelBarron::buildLogZTable() {
    if (sTableInitialized) return;

    const int    N_ALPHA = 121;    // α ∈ [−10, 2], step 0.1
    const int    N_X     = 20000;  // integration points on [0, X_MAX]
    const double X_MAX   = 50.0;
    const double dx      = X_MAX / static_cast<double>(N_X);

    sLogZTable.resize(N_ALPHA);
    for (int i = 0; i < N_ALPHA; i++) {
        const double alpha = -10.0 + i * 0.1;
        double Z = 0.0;
        for (int j = 0; j < N_X; j++) {
            const double x  = (j + 0.5) * dx;
            const double r2 = x * x;
            Z += std::exp(-barronLossRaw(r2, alpha));
        }
        Z = Z * dx * 2.0;  // symmetry: multiply by 2 for [−X_MAX, 0] half
        sLogZTable[i] = std::log(std::max(Z, 1e-300));
    }
    sTableInitialized = true;
}

// ---------------------------------------------------------------------------
// robustify — g2o convention
// Input:   squaredError = e^T Ω e  (chi² value)
// Output:  rho[0] = robustified cost
//          rho[1] = dρ/d(squaredError)  [≈ 1 for inliers, → 0 for outliers]
//          rho[2] = d²ρ/d(squaredError)² [< 0 for robust kernels]
//
// Formula:  ρ = 2c²·|α−2|/α · [u^(α/2) − 1]   where u = e/(|α−2|c²) + 1
// Derivatives:
//          rho[1] = u^(α/2 − 1)
//          rho[2] = (α/2 − 1)/(|α−2|c²) · u^(α/2 − 2)
// ---------------------------------------------------------------------------
void RobustKernelBarron::robustify(double e, Eigen::Vector3d& rho) const {
    if (e <= 0.0) {
        rho[0] = 0.0;
        rho[1] = 1.0;
        rho[2] = 0.0;
        return;
    }

    // --- Special case: α ≈ 2  (transparent L2 kernel) ---
    if (std::abs(_alpha - 2.0) < 1e-6) {
        rho[0] = e;
        rho[1] = 1.0;
        rho[2] = 0.0;
        return;
    }

    // --- Special case: α ≈ 0  (Cauchy / log) ---
    // ρ = 2c²·log(e/(2c²) + 1)
    if (std::abs(_alpha) < 1e-6) {
        const double aux = e / (2.0 * _csqr) + 1.0;
        rho[0] = 2.0 * _csqr * std::log(aux);
        rho[1] = 1.0 / aux;
        rho[2] = -(1.0 / (2.0 * _csqr)) * rho[1] * rho[1];
        return;
    }

    // --- Special case: α < −50  (Welsch approximation) ---
    // ρ = 2c²·(1 − exp(−e/(2c²)))
    if (_alpha < -50.0) {
        const double t = e / (2.0 * _csqr);
        const double w = std::exp(-t);
        rho[0] = 2.0 * _csqr * (1.0 - w);
        rho[1] = w;
        rho[2] = -w / (2.0 * _csqr);
        return;
    }

    // --- General case: α ∈ (−50, 0) ∪ (0, 2) ---
    const double abs_a2 = std::abs(_alpha - 2.0);   // = 2 − α for α < 2
    const double u      = e / (abs_a2 * _csqr) + 1.0;
    const double upow   = std::pow(std::max(u, 1e-300), _alpha / 2.0);

    rho[0] = 2.0 * _csqr * (abs_a2 / _alpha) * (upow - 1.0);
    rho[1] = upow / u;                                       // u^(α/2 − 1)
    rho[2] = (_alpha / 2.0 - 1.0) / (abs_a2 * _csqr) * (upow / (u * u)); // u^(α/2 − 2)
}

// ---------------------------------------------------------------------------
// estimateAlpha — MLE grid search
// Minimizes: Σ [log Z(α) + ρ_raw(eᵢ/c²; α)]  over α ∈ [−10, 2], step 0.1
//
// sq_residuals: chi² values from e->chi2()  (NOT robustified chi²)
// c: same scale parameter as used in robustify (setC)
// ---------------------------------------------------------------------------
double RobustKernelBarron::estimateAlpha(const std::vector<double>& sq_residuals,
                                          double c) {
    if (sq_residuals.empty()) return 2.0;

    buildLogZTable();   // one-time cost

    const int    N_ALPHA = 121;
    const double csqr    = c * c;
    const double n       = static_cast<double>(sq_residuals.size());

    double best_alpha = 2.0;
    double best_cost  = std::numeric_limits<double>::max();

    for (int i = 0; i < N_ALPHA; i++) {
        const double alpha = -10.0 + i * 0.1;

        // Cost = N·log Z(α) + Σ ρ_raw(eᵢ/c²; α)
        // Normalize chi2 by c² to match unit-scale Barron formula (c_raw = 1)
        double cost = n * sLogZTable[i];
        for (const double sq : sq_residuals) {
            cost += barronLossRaw(sq / csqr, alpha);
        }

        if (cost < best_cost) {
            best_cost  = cost;
            best_alpha = alpha;
        }
    }

    return best_alpha;
}

G2O_REGISTER_ROBUST_KERNEL(Barron, RobustKernelBarron)

} // namespace g2o
