#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include "gen_lookup.h"
#include "icdf.h"
#include "yaml_parse.h"


int gen_lookup_c0(const RngData *rng_data, unsigned long long *buffer, unsigned long long *max_out)
{
    if (rng_data->BY > 64)
    {
        printf("rng_data->BY too large to store ICDF/lookup output in 64 bit unsigned long long\n");
        exit(EXIT_FAILURE);
    }

    uint16_t num_sect = yaml_parse_num_sections(rng_data);
    unsigned long num_subsect = yaml_parse_num_subsections(rng_data);

    /* ICDF parameters */
    double mu = 0.0;
    double b = 1.0;

    /* Determine maximum output value and scale factor for quantisation of ICDF */
    uint8_t remaining_mant_bits = rng_data->MANT_BW - rng_data->K;

    // Smallest division within smallest subsection for part = false
    double min_x_coord = (double)(1.0 / (1 << (rng_data->GROWING_OCT + 1) ));  // Octave width
    min_x_coord /= num_subsect;  // Subsection width
    min_x_coord /= 1 << remaining_mant_bits;  // Mantissa division width

    double max_abs = 0.0 - icdf_laplace_double(min_x_coord, mu, b);

    if(rng_data->BY - 1 - ceil(log2(max_abs)) >= 8*sizeof(int))
    {
        printf("scale_exp is too large to store in int\n");
        exit(EXIT_FAILURE);
    }

    int scale_exp = rng_data->BY - 1 - (int)ceil(log2(max_abs));
    *max_out = icdf_laplace_ull(min_x_coord, mu, b, scale_exp);

    for(uint16_t section = 0; section < num_sect; section++)
    {
        double octave_width;
        double octave_bound;
        bool part = false;

        if(section == rng_data->GROWING_OCT - 1)
        {
            // Section closest to zero is the same width as the one after
            part = false;
            octave_width = 1.0 / (1 << (section + 2));
            octave_bound = 1.0 / (1 << (section + 2));  // Upper bound
        }
        else if(section == num_sect - 1)
        {
            // Final section has same width as penultimate section
            part = true;
            uint16_t exp = section - rng_data->GROWING_OCT;
            octave_width = 1.0 / (1 << (exp + 2));
            octave_bound = 0.5 - octave_width; // Lower bound
        }
        else
        {
            uint16_t exp = section;
            part = false;
            if(section >= rng_data->GROWING_OCT)
            {
                exp -= rng_data->GROWING_OCT;
                part = true;
            }

            octave_width = 1.0 / (1 << (exp + 3));

            if(part)
            {
                octave_bound = 0.5 - 1.0 / (1 << (exp + 2)); // Lower bound
            }
            else
            {
                octave_bound = 1.0 / (1 << (exp + 2)); // Upper bound
            }
        }

        for(unsigned long subsection = 0; subsection < num_subsect; subsection++)
        {
            /* Calculate c0 from ICDF for each subsection boundary in the section */
            double subsection_width = octave_width / num_subsect;
            double x_coord;
            if(part)
            {
                x_coord = octave_bound + (subsection+1) * subsection_width;
            }
            else
            {
                x_coord = octave_bound - subsection * subsection_width;
            }

            size_t index = section << rng_data->K | subsection;
            buffer[index] = icdf_laplace_ull(x_coord, mu, b, scale_exp);
        }
    }

    return 0;
}

int gen_lookup_c1(const RngData *rng_data, unsigned long long *c0, unsigned long long max_out, unsigned long long *c1)
{
    unsigned long num_subsect = yaml_parse_num_subsections(rng_data);
    size_t len = (size_t) yaml_parse_num_sections(rng_data) * num_subsect;
    uint8_t remaining_mant_bits = rng_data->MANT_BW - rng_data->K;

    for(size_t i = 0; i < len; i++)
    {
        if(i == rng_data->GROWING_OCT * num_subsect - 1)
        {
            // Subsection containing zero asymptote
            c1[i] = (unsigned long long)round((double)(max_out - c0[i])/((1 << remaining_mant_bits) - 1));
        }
        else if(i == rng_data->GROWING_OCT * num_subsect)
        {
            // First subsection in part == 1 region
            c1[i] = (c0[0] - c0[i]) >> remaining_mant_bits;
        }
        else if(i < rng_data->GROWING_OCT * num_subsect)
        {
            // Default for part = 0
            c1[i] = (c0[i+1] - c0[i]) >> remaining_mant_bits;
        }
        else
        {
            // Default for part = 1
            c1[i] = (c0[i-1] - c0[i]) >> remaining_mant_bits;
        }
    }
    return 0;
}

int gen_lookup_save_cx(const char *const filename, unsigned long long *cx, size_t len)
{
    int rtn = 0;
    FILE *file = fopen(filename,"w");
    if(!file)
    {
        printf("Failed to create file '%s'", filename);
        // return 1;
        exit(EXIT_FAILURE);
    }

    for(size_t i = 0; i < len; i++)
    {
        rtn += fprintf(file, "%llx\n", cx[i]);
    }

    fclose(file);
    printf("Generated file \"%s\"\n", filename);
    return 0;
}