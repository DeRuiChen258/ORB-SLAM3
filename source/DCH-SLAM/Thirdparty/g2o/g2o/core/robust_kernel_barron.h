// Barron General Adaptive Robust Kernel for g2o
// Based on: "A General and Adaptive Robust Loss Function", Barron, CVPR 2019
// and VAR-SLAM: "Versatile and Accurate SLAM with Adaptive Robust Kernel", IROS 2025

#ifndef G2O_ROBUST_KERNEL_BARRON_H
#define G2O_ROBUST_KERNEL_BARRON_H

#include "robust_kernel.h"
#include <vector>
#include <cmath>
#include <limits>

namespace g2o {

/**
 * \brief Barron general adaptive robust kernel
 *
 * Parameterized loss function that unifies many common robust kernels:
 *   α = 2  → L2 (quadratic, no robustification)
 *   α = 1  → pseudo-Huber (smooth L1)
 *   α = 0  → Cauchy / Lorentzian (log)
 *   α → -∞ → Welsch / Leclerc
 *
 * g2o convention (rho[1] = 1 for small inlier errors):
 *   ρ(e; α, c) = 2c² · |α−2|/α · [(e / (|α−2|c²) + 1)^(α/2) − 1]
 *
 * where e = squaredError = e^T Ω e (chi² value from g2o).
 *
 * Derivatives:
 *   rho[1] = u^(α/2 − 1)   where u = e/(|α−2|c²) + 1
 *   rho[2] = (α/2 − 1) / (|α−2|c²) · u^(α/2 − 2)
 *
 * Special cases (handled explicitly to avoid 0/0):
 *   α = 2:  L2 transparent   → rho = {e, 1, 0}
 *   α = 0:  Cauchy/log       → rho[0] = 2c²·log(e/(2c²)+1)
 *   α <-50: Welsch approx    → rho[0] = 2c²·(1 − exp(−e/(2c²)))
 */
class RobustKernelBarron : public RobustKernel {
public:
    RobustKernelBarron();

    // Shape parameter α ∈ (−∞, 2]. Clamped to 2.0 if set higher.
    void setAlpha(double alpha);
    double getAlpha() const { return _alpha; }

    // Scale parameter c (analogous to delta in Huber).
    // Set c = sqrt(chi²_threshold), e.g. sqrt(5.991) for mono, sqrt(7.815) for stereo.
    void setC(double c);
    double getC() const { return _c; }

    virtual void robustify(double squaredError, Eigen::Vector3d& rho) const override;

    /**
     * Estimate the optimal alpha from a set of chi² residuals (e->chi2() values).
     * Uses MLE grid search: α* = argmin_α Σ[log Z(α) + ρ_raw(eᵢ/c²; α)]
     * Grid: α ∈ [−10, 2], step 0.1 (121 values).
     *
     * @param sq_residuals  Vector of chi2 values (squaredError from g2o edges)
     * @param c             Scale parameter (same c used in setC)
     * @return              Estimated optimal alpha
     */
    static double estimateAlpha(const std::vector<double>& sq_residuals, double c);

private:
    double _alpha;
    double _c;
    double _csqr;   // c² cached

    // log Z(α) lookup table for α ∈ [−10, 2] step 0.1 (121 entries).
    // Z(α) = ∫ exp(−ρ_raw(x²; α, c=1)) dx  (partition function, truncated domain).
    static std::vector<double> sLogZTable;
    static bool sTableInitialized;
    static void buildLogZTable();

    // Unnormalized Barron loss (paper convention, c=1): input r2 = x² (raw squared residual)
    static double barronLossRaw(double r2, double alpha);
};

} // namespace g2o

#endif // G2O_ROBUST_KERNEL_BARRON_H
