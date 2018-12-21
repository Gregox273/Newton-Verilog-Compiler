#include <stdio.h>
#include "icdf.h"
#include "yaml_parse.h"
#include "gen_vh.h"

int main(int argc, char **argv) {
    int rtn = 0;
    printf("\nStarting Newton to Verilog Compiler Backend...");

    /* Parse YAML file
     * Based on example by Andrew Poelstra, 2011
     * (https://www.wpsoftware.net/andrew/pages/libyaml.html)
     */
    const char filename[] = "privacy.yaml";
    URNG_data urng_data;
    RNG_data rng_data;
    rtn += parse_yaml(filename, &urng_data, &rng_data);

    rtn += gen_urng_vh("verilog", &urng_data);
    rtn += gen_rng_vh("verilog",&rng_data);

    printf("\n");
    return rtn;
}
