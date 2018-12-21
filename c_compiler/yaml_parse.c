#include <yaml.h>
#include <stdlib.h>
#include <string.h>
#include "yaml_parse.h"

typedef enum heading_1
{
    URNG_HEADING_1,
    RNG_HEADING_1,
    NUM_HEADINGS
}Heading_1;

// Fields should be in the order that they appear in the relevant structs
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
    URNG_data *urng_data_addr;
    RNG_data *rng_data_addr;
    Heading_1 current_heading_1;  // Name of struct currently being populated
    uint8_t current_field;  // Current field to fill in
    uint8_t *current_field_addr;
}Parser_state;

Heading_1 get_current_heading(const yaml_event_t *const event)
{
    /* Return Heading_1 number based on name in yaml event */
    if(strncmp((char *)event->data.scalar.value, "URNG", 4)==0)
    {
        return URNG_HEADING_1;
    }
    else if(strncmp((char *)event->data.scalar.value, "RNG", 3)==0)
    {
        return RNG_HEADING_1;
    }
    else{
        printf("Unrecognised heading \"%s\"",event->data.scalar.value);
        exit(EXIT_FAILURE);
    }
}

Urng_fields get_current_field_urng(const yaml_event_t *const event, Parser_state *const state)
{
    if(strncmp((char *)event->data.scalar.value, "BX", 2)==0) {
        state->current_field_addr = &state->urng_data_addr->BX;
        return URNG_BX;
    }
    else
    {
        printf("Unrecognised heading \"%s\"",event->data.scalar.value);
        exit(EXIT_FAILURE);
    }
}

Rng_fields get_current_field_rng(const yaml_event_t *const event, Parser_state *const state)
{
    if(strncmp((char *)event->data.scalar.value, "BY", 2)==0)
    {
        state->current_field_addr = &state->rng_data_addr->BY;
        return RNG_BY;
    }
    else if(strncmp((char *)event->data.scalar.value, "K", 1)==0)
    {
        state->current_field_addr = &state->rng_data_addr->K;
        return RNG_K;
    }
    else if(strncmp((char *)event->data.scalar.value, "MANT_BW", 7)==0)
    {
        state->current_field_addr = &state->rng_data_addr->MANT_BW;
        return RNG_MANT_BW;
    }
    else if(strncmp((char *)event->data.scalar.value, "GROWING_OCT", 11)==0)
    {
        state->current_field_addr = &state->rng_data_addr->GROWING_OCT;
        return RNG_GROWING_OCT;
    }
    else if(strncmp((char *)event->data.scalar.value, "DIMINISHING_OCT", 15)==0)
    {
        state->current_field_addr = &state->rng_data_addr->DIMINISHING_OCT;
        return RNG_DIMINISHING_OCT;
    }
    else
    {
        printf("Unrecognised heading \"%s\"",event->data.scalar.value);
        exit(EXIT_FAILURE);
    }
}

uint8_t get_current_field(const yaml_event_t *const event, Parser_state *const state)
{
    switch(state->current_heading_1)
    {
        case URNG_HEADING_1:
            return get_current_field_urng(event, state);
        case RNG_HEADING_1:
            return get_current_field_rng(event, state);
        default:
            printf("Forgot to add case for heading no. \"%d\"",state->current_heading_1);
            exit(EXIT_FAILURE);
    }
}

void handle_value(const yaml_event_t *const event, Parser_state *state)
{
    // Add switch case here to accommodate fields that cannot be handled in the following default case:
    *state->current_field_addr = atoi((char *)event->data.scalar.value);
}

int parse_yaml(const char *filename, URNG_data *const urng_data, RNG_data *const rng_data)
{
    FILE *yaml_file = fopen(filename, "r");
    printf("\nParsing YAML file: '%s'", filename);

    yaml_parser_t parser;
    yaml_event_t event;

    // Initialise parser
    if(!yaml_parser_initialize(&parser))
    {
        fputs("\nFailed to initialize parser!", stderr);
        return 1;
    }
    if(yaml_file == NULL)
    {
        fputs("\nFailed to open file %s!", stderr);
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
            printf("\nParser error %d", parser.error);
            //exit(EXIT_FAILURE);
            return 1;
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
                        printf("\nUnexpected value \"%s\"",event.data.scalar.value);
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
    return 0;
}

