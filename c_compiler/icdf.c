#include "icdf.h"
#include <math.h>
#include <stdint.h>

double laplace_inv_cdf(double p, double mu, double b)
{
    if (p < 0.5)
    {
        return mu + b * log(2 * p);
    }
    else
    {
        return mu - b * log(2 - 2 * p);
    }
}