#ifndef _YAML_PARSE_H_
#define _YAML_PARSE_H_

#include <stdint.h>

/* Data structs: non-uint8_t fields should be located after uint8_t fields */
typedef struct __attribute__((packed))
{
    uint8_t BX;
}URNG_data;

typedef struct __attribute__((packed))
{
    uint8_t BY;
    uint8_t K;
    uint8_t MANT_BW;
    uint8_t GROWING_OCT;
    uint8_t DIMINISHING_OCT;
}RNG_data;

int parse_yaml(const char *filename, URNG_data *const urng_data, RNG_data *const rng_data);

#endif // _YAML_PARSE_H_
