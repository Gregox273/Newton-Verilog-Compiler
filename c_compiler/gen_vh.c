#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "gen_vh.h"
#include "yaml_parse.h"

#define FLAG 35  // '#' character

int gen_file(const char *src, const char *dest, int flag, const char *data)
{
    /* Copy contents of source file to destination file, replacing flag with relevant data
     * src  -- source file path
     * dest -- destination file path
     * flag -- ASCII character to replace with data
     * data -- string to insert in place of flag
     */
    FILE *src_file = fopen(src,"r");
    if(!src_file)
    {
        printf("Failed to open source file '%s'\n", src);
        //return 1;
        exit(EXIT_FAILURE);
    }

    FILE *dest_file = fopen(dest,"w");
    if(!dest_file)
    {
        printf("Failed to create destination file '%s'\n", dest);
        //return 1;
        exit(EXIT_FAILURE);
    }

    int c;
    while ((c = fgetc(src_file)) != EOF)
    {
        if(c==flag)
        {
            fputs(data, dest_file);
        }
        else
        {
            fputc(c, dest_file);
        }
    }

    fclose (src_file);
    fclose (dest_file);

    printf("Generated file \"%s\"\n", dest);
    return 0;
}

int gen_vh_rng(const char *destination, const RngData *const rng_data)
{
    int rtn = 0;

    const char template_file[] = "templates/templ_rng.vh";

    // Determine length of required buffer
    int len = snprintf(NULL, 0,
            "`define RNG_BY %d\n"
            "`define RNG_K %d\n"
            "`define RNG_MANT_BW %d\n"
            "`define RNG_EXP_BW `URNG_BX - `RNG_MANT_BW - 2\n"
            "`define RNG_GROWING_OCT %d\n"
            "`define RNG_DIMINISHING_OCT %d",
            rng_data->BY,
            rng_data->K,
            rng_data->MANT_BW,
            rng_data->GROWING_OCT,
            rng_data->DIMINISHING_OCT);

    char data[len+1];
    snprintf(data, len+1,
             "`define RNG_BY %d\n"
             "`define RNG_K %d\n"
             "`define RNG_MANT_BW %d\n"
             "`define RNG_EXP_BW `URNG_BX - `RNG_MANT_BW - 2\n"
             "`define RNG_GROWING_OCT %d\n"
             "`define RNG_DIMINISHING_OCT %d",
             rng_data->BY,
             rng_data->K,
             rng_data->MANT_BW,
             rng_data->GROWING_OCT,
             rng_data->DIMINISHING_OCT);

    rtn += gen_file(template_file, destination, FLAG, data);

    return rtn;
}

int gen_vh_urng(const char *destination, const UrngData *const urng_data)
{
    int rtn = 0;

    const char template_file[] = "templates/templ_urng.vh";

    // Determine length of required buffer
    int len = snprintf(NULL, 0,
                       "`define URNG_BX %d\n",
                       urng_data->BX);

    char data[len+1];
    snprintf(data, len+1,
             "`define URNG_BX %d\n",
             urng_data->BX);

    rtn += gen_file(template_file, destination, FLAG, data);

    return rtn;
}