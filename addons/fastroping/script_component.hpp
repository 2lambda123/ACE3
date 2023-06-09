#define COMPONENT fastroping
#define COMPONENT_BEAUTIFIED Fastroping
#include "\z\ace\addons\main\script_mod.hpp"

// #define DRAW_FASTROPE_INFO
// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE
// #define ENABLE_PERFORMANCE_COUNTERS

#ifdef DEBUG_ENABLED_FASTROPING
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_FASTROPING
    #define DEBUG_SETTINGS DEBUG_SETTINGS_FASTROPING
#endif

#include "\z\ace\addons\main\script_macros.hpp"
#include "script_macros.hpp"

#define DEFAULT_ROPE_LENGTH 34.5

#define ANIMS_HOOK ["extendHookRight", "extendHookLeft"]
#define ANIMS_ANIMATEDOOR ["door_R", "door_L", "CargoRamp_Open", "Door_rear_source", "Door_6_source", "CargoDoorR", "CargoDoorL"]
#define ANIMS_ANIMATE ["dvere1_posunZ", "dvere2_posunZ", "doors"]
