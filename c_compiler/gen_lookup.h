#ifndef _GEN_LOOKUP_H_
#define _GEN_LOOKUP_H_
#include <stddef.h>
#include "yaml_parse.h"

/* Generate c0 coefficients for lookup table
 *
 * rng_data -- pointer to RNG data from YAML file
 * buffer   -- pointer to buffer to store coefficients
 */
int gen_lookup_c0(const RngData *rng_data, by_t *buffer, by_t *max_out);

/* Generate c1 coefficients using c0 coefficients
 *
 * rng_data -- pointer to RNG data from YAML file
 * c0       -- pointer to filled c0 array
 * max_out  -- maximum output value from quantised ICDF function
 * c1       -- pointer to c1 array to store coefficients
 */
int gen_lookup_c1(const RngData *rng_data, by_t *c0, by_t max_out, by_t *c1);

/* Save generated array to file in hex form, separated by "\n"
 *
 * filename -- path to file
 * cx       -- pointer to array containing data to save
 * len      -- number of elements in array cx
 */
int gen_lookup_save_cx(const char *const filename, by_t *cx, size_t len);

#endif //_GEN_LOOKUP_H_
