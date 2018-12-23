#ifndef _GEN_VH_H_
#define _GEN_VH_H_

#include "yaml_parse.h"

/* Generate .vh file containing RNG parameters
 *
 * destination -- path to destination .vh file
 * rng_data    -- RNG data from YAML file
 */
int gen_vh_rng(const char *destination, const RngData *const rng_data);

/* Generate .vh file containing URNG parameters
 *
 * destination -- path to destination .vh file
 * urng_data   -- URNG data from YAML file
 */
int gen_vh_urng(const char *destination, const UrngData *const urng_data);

#endif //_GEN_VH_H_
