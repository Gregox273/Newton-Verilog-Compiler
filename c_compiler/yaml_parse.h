#ifndef _YAML_PARSE_H_
#define _YAML_PARSE_H_

#include <stdint.h>
#include "types.h"

typedef struct
{
    uint8_t BX;
}UrngData;

typedef struct
{
    uint8_t BY;
    uint8_t K;
    uint8_t MANT_BW;
    uint8_t GROWING_OCT;
    uint8_t DIMINISHING_OCT;
    uint8_t EXP_BW;
    uint8_t MAX_G_D;
    uint8_t SEC_ADDR_SIZE;
}RngData;

/* Parse YAML file, extracting and storing useful information
 *
 * filename  -- path to YAML file
 * urng_data -- pointer to struct to store URNG data within
 * rng_data  -- pointer to struct to store RNG data within
 */
int yaml_parse_parse(const char *filename, UrngData *const urng_data, RngData *const rng_data);

/* Calculate number of sections based on RNG data from YAML file
 *
 * rng_data -- pointer to RNG data struct
 */
section_t yaml_parse_num_sections(const RngData *const rng_data);

/* Calculate number of subsections based on RNG data from YAML file
 *
 * rng_data -- pointer to RNG data struct
 */
subsection_t yaml_parse_num_subsections(const RngData *const rng_data);

#endif // _YAML_PARSE_H_
