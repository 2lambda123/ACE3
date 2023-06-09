#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {QGVAR(moduleGroupSettings)};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {"ace_common"};
        author = ECSTRING(common,ACETeam);
        authors[] = {"Dslyecxi", "MikeMatrix"};
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

#include "ACE_Settings.hpp"
#include "CfgEventHandlers.hpp"
#include "CfgVehicles.hpp"
