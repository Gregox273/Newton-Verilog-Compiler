#ifndef _TYPES_H_
#define _TYPES_H_

#include <stdint.h>

typedef uint16_t section_t;         // 16 bits used to index section number
typedef unsigned long subsection_t; // 32 bits used to index subsection number
typedef unsigned long long by_t;    // 64 bits used to store ICDF output/lookup table entries
typedef int scale_t;                // <16 bits used to store ICDF scale argument

#endif //_TYPES_H_
