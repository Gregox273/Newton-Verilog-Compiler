#include <yaml.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "yaml_parse.h"

typedef enum heading_1
{
    URNG_HEADING_1,
    RNG_HEADING_1,
    NUM_HEADINGS
}Heading_1;

typedef enum urng_fields
{
    URNG_BX
}Urng_fields;

typedef enum rng_fields
{
    RNG_BY,
    RNG_K,
    RNG_MANT_BW,
    RNG_GROWING_OCT,
    RNG_DIMINISHING_OCT
}Rng_fields;

typedef struct parser_state
{
    // Addresses of data structs to populate from YAML file
    UrngData *urng_data_addr;
    RngData *rng_data_addr;
    Heading_1 current_heading_1;  // Name of struct currently being populated
    uint8_t current_field;        // Current field to fill in
    void *current_field_addr;  // Address of current field
}Parser_state;

Heading_1 get_current_heading(const yaml_event_t *const event)
{
    /* Return Heading_1 number based on name in yaml event
     *
     * event -- pointer to yaml parser event
     */
    if(strncmp((char *)event->data.scalar.value, "URNG", 4)==0)
    {
        return URNG_HEADING_1;
    }
    else if(strncmp((char *)event->data.scalar.value, "RNG", 3)==0)
    {
        return RNG_HEADING_1;
    }
    else{
        printf("Unrecognised heading \"%s\"\n",event->data.scalar.value);
        exit(EXIT_FAILURE);
    }
}

Urng_fields get_current_field_urng(const yaml_event_t *const event, Parser_state *const state)
{
    /* Return Urng field number based on name in yaml event
     *
     * event -- pointer to yaml parser event
     * state -- pointer to state of parser loop
     */
    if(strncmp((char *)event->data.scalar.value, "BX", 2)==0) {
        state->current_field_addr = (void*)&state->urng_data_addr->BX;
        return URNG_BX;
    }
    else
    {
        printf("Unrecognised heading \"%s\"\n",event->data.scalar.value);
        exit(EXIT_FAILURE);
    }
}

Rng_fields get_current_field_rng(const yaml_event_t *const event, Parser_state *const state)
{
    /* Return Rng field number based on name in yaml event
     *
     * event -- pointer to yaml parser event
     * state -- pointer to state of parser loop
     */
    if(strncmp((char *)event->data.scalar.value, "BY", 2)==0)
    {
        state->current_field_addr = (void*)&state->rng_data_addr->BY;
        return RNG_BY;
    }
    else if(strncmp((char *)event->data.scalar.value, "K", 1)==0)
    {
        state->current_field_addr = (void*)&state->rng_data_addr->K;
        return RNG_K;
    }
    else if(strncmp((char *)event->data.scalar.value, "MANT_BW", 7)==0)
    {
        state->current_field_addr = (void*)&state->rng_data_addr->MANT_BW;
        return RNG_MANT_BW;
    }
    else if(strncmp((char *)event->data.scalar.value, "GROWING_OCT", 11)==0)
    {
        state->current_field_addr = (void*)&state->rng_data_addr->GROWING_OCT;
        return RNG_GROWING_OCT;
    }
    else if(strncmp((char *)event->data.scalar.value, "DIMINISHING_OCT", 15)==0)
    {
        state->current_field_addr = (void*)&state->rng_data_addr->DIMINISHING_OCT;
        return RNG_DIMINISHING_OCT;
    }
    else
    {
        printf("Unrecognised heading \"%s\"\n",event->data.scalar.value);
        exit(EXIT_FAILURE);
    }
}

uint8_t get_current_field(const yaml_event_t *const event, Parser_state *const state)
{
    /* Return field number from yaml event based on current Heading_1 and parser state
     *
     * event -- pointer to yaml parser event
     * state -- pointer to state of parser loop
     */
    switch(state->current_heading_1)
    {
        case URNG_HEADING_1:
            return get_current_field_urng(event, state);
        case RNG_HEADING_1:
            return get_current_field_rng(event, state);
        default:
            printf("Forgot to add case for heading no. \"%d\"\n",state->current_heading_1);
            exit(EXIT_FAILURE);
    }
}

void handle_value(const yaml_event_t *const event, Parser_state *state)
{
    /* Store value from YAML file in relevant struct
     *
     * event -- pointer to YAML parser event
     * state -- pointer to state of parser loop
     */

    // Add switch case here to accommodate fields that cannot be handled in the following default case:
    *(uint8_t*)state->current_field_addr = (uint8_t)atoi((char *)event->data.scalar.value);
}

int yaml_parse_parse(const char *filename, UrngData *const urng_data, RngData *const rng_data)
{
    FILE *yaml_file = fopen(filename, "r");
    printf("Parsing YAML file: \"%s\"\n", filename);

    yaml_parser_t parser;
    yaml_event_t event;

    // Initialise parser
    if(!yaml_parser_initialize(&parser))
    {
        printf("Failed to initialize parser!\n");
        fclose (yaml_file);
        return 1;
    }
    if(yaml_file == NULL)
    {
        printf("Failed to open file %s!\n", filename);
        return 1;
    }

    yaml_parser_set_input_file(&parser, yaml_file);

    uint8_t level = 0;  // Hierarchical level within the yaml file
    Parser_state state = {
            .urng_data_addr = urng_data,
            .rng_data_addr = rng_data,
            .current_heading_1 = NUM_HEADINGS,
            .current_field = 0,
            .current_field_addr = NULL
    };

    // Add new structs here, add their addresses to the data_structs array below
    size_t data_structs[NUM_HEADINGS];
    data_structs[URNG_HEADING_1] = (size_t)&urng_data;
    data_structs[RNG_HEADING_1] = (size_t)&rng_data;

    do
    {
        if (!yaml_parser_parse(&parser, &event)) {
            printf("Parser error %d\n", parser.error);
            exit(EXIT_FAILURE);
        }

        switch(event.type)
        {
            case YAML_MAPPING_START_EVENT: level++; break;
            case YAML_MAPPING_END_EVENT:   level--; break;
            /* Data */
            case YAML_SCALAR_EVENT:
                switch(level)
                {
                    case 1:
                        state.current_heading_1 = get_current_heading(&event);
                        break;
                    case 2:
                        if(!state.current_field_addr)
                        {
                            // Read key
                            state.current_field = get_current_field(&event, &state);
                        }
                        else
                        {
                            // Read value
                            handle_value(&event, &state);
                            state.current_field_addr = NULL;
                        }
                        break;

                    default:
                        printf("Unexpected value \"%s\"\n",event.data.scalar.value);
                        exit(EXIT_FAILURE);
                }
                break;
            default:
                // Do nothing
                break;
        }
        if(event.type != YAML_STREAM_END_EVENT)
            yaml_event_delete(&event);
    } while(event.type != YAML_STREAM_END_EVENT);

    // Cleanup YAML parser
    yaml_event_delete(&event);
    yaml_parser_delete(&parser);
    fclose(yaml_file);

    // TODO: check whether values are valid e.g. MANT_BW must be < BY
    // See Python prototype for some examples of sanity checks
    // E.g. limit K to 48 bits or less (see main.c)
    return 0;
}

section_t yaml_parse_num_sections(const RngData *const rng_data)
{
    // Sum of two uint8_t will fit into uint16_t
    return (section_t)(rng_data->GROWING_OCT + rng_data->DIMINISHING_OCT);
}

subsection_t yaml_parse_num_subsections(const RngData *const rng_data)
{
    if (rng_data->K > 8*sizeof(subsection_t))
    {
        printf("rng_data->K too large to store subsection addr in 32 bit unsigned long\n");
        exit(EXIT_FAILURE);
    }
    return 1UL << rng_data->K;
}

