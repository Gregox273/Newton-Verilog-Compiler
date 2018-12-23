#include <stdio.h>
#include <unistd.h>
#include "yaml_parse.h"
#include "gen_vh.h"
#include "gen_lookup.h"
#include "types.h"

int main(int argc, char **argv) {
    int rtn = 0;
    chdir(WORKING_DIR);

    printf("\nStarting Newton to Verilog Compiler Backend...\n");

    /* Parse YAML file
     * Based on example by Andrew Poelstra, 2011
     * (https://www.wpsoftware.net/andrew/pages/libyaml.html)
     */
    const char filename[] = "privacy.yaml";
    UrngData urng_data;
    RngData rng_data;
    rtn += yaml_parse_parse(filename, &urng_data, &rng_data);

    rtn += gen_vh_urng("verilog/urng.vh", &urng_data);
    rtn += gen_vh_rng("verilog/rng.vh", &rng_data);

    /* Generate lookup table entries */
    section_t num_sect = yaml_parse_num_sections(&rng_data);
    subsection_t num_subsect = yaml_parse_num_subsections(&rng_data);
    size_t len = (size_t)num_sect * num_subsect;

    by_t c0[len];  //WARNING: may overflow if K > 48 for 64 bit size_t
    by_t c1[len];  //WARNING: may overflow if K > 48 for 64 bit size_t
    by_t lookup_max_out;

    rtn += gen_lookup_c0(&rng_data, c0, &lookup_max_out);
    rtn += gen_lookup_c1(&rng_data, c0, lookup_max_out, c1);

    rtn += gen_lookup_save_cx("verilog/c0.mem", c0, len);
    rtn += gen_lookup_save_cx("verilog/c1.mem", c1, len);

//    for(size_t i = 0; i < len; i++)
//    {
//        printf("%llu    %llu\n",c0[i], c1[i]);
//    }

    return rtn;
}
