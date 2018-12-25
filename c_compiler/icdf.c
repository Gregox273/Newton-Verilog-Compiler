#include "icdf.h"
#include <math.h>
#include <stdint.h>
#include <gsl/gsl_cdf.h>
#include <gsl/gsl_randist.h>

double icdf_laplace_double(double p, double mu, double b)
{
    if (p < 0.5)
    {
        return mu + gsl_cdf_laplace_Pinv(p, b);
    }
    else
    {
        return mu + gsl_cdf_laplace_Qinv(p, b);
    }
}

by_t icdf_laplace_ull(double p, double mu, double b, scale_t scale_exp)
{
    if(scale_exp >= 0)
    {
        return (by_t)round((1ULL << scale_exp) * fabs(icdf_laplace_double(p, mu, b)));
    }
    else
    {
        return (by_t)round(fabs(icdf_laplace_double(p, mu, b)) / (1ULL << (0-scale_exp)));
    }
}