#ifndef _ICDF_H_
#define _ICDF_H_

#include "types.h"


/* Inverse CDF for Laplace distribution
 *
 * p  -- ICDF function input
 * mu -- Mean value for Laplace distribution
 * b  -- Shape parameter for Laplace distribution
 */
double icdf_laplace_double(double p, double mu, double b);


/* Return quantised absolute value of ICDF for Laplace distribution
 *
 * p         -- ICDF function input
 * mu        -- Mean value for Laplace distribution
 * b         -- Shape parameter for Laplace distribution
 * scale_exp -- Quantisation step = 2^-scale_exp
 */
by_t icdf_laplace_ull(double p, double mu, double b, scale_t scale_exp);

#endif //_ICDF_H_
