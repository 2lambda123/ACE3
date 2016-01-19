/*
 * Author: Commy2 and CAA-Picard
 * Handle weapon fire
 *
 * Argument:
 * 0: unit - Object the event handler is assigned to <OBJECT>
 * 1: weapon - Fired weapon <STRING>
 * 2: muzzle - Muzzle that was used <STRING>
 * 3: mode - Current mode of the fired weapon <STRING>
 * 4: ammo - Ammo used <STRING>
 * 5: magazine - magazine name which was used <STRING>
 * 6: projectile - Object of the projectile that was shot <OBJECT>
 *
 * Return value:
 * None
 *
 * Public: No
 */
#include "script_component.hpp"

BEGIN_COUNTER(firedEH);

params ["_unit", "_weapon", "_muzzle", "", "_ammo", "", "_projectile"];
TRACE_5("params",_unit,_weapon,_muzzle,_ammo,_projectile);

if (((!GVAR(overheatingDispersion)) && {_unit != ACE_player}) //If no dispersion, only run when local
        || {!([_unit] call EFUNC(common,isPlayer))} //Ignore AI
        || {(_unit distance ACE_player) > 3000} //Ignore far away shots
        || {(_muzzle != (primaryWeapon _unit)) && {_muzzle != (handgunWeapon _unit)}}) exitWith { // Only rifle or pistol muzzles (ignore grenades / GLs)
    END_COUNTER(firedEH);
};

// Compute new temperature if the unit is the local player
if (_unit == ACE_player) then {
    _this call FUNC(overheat);
};

// Get current temperature from the unit variable
private _temperature = _unit getVariable [format [QGVAR(%1_temp), _weapon], 0]
private _scaledTemperature = linearConversion [0, 1000, _temperature, 0, 1, true];

TRACE_2("",_temperature,_scaledTemperature);

//Get weapon data from cache:
private _weaponData = GVAR(weaponInfoCache) getVariable _weapon;
if (isNil "_weaponData") then {
    private _dispersion = if (isNumber (configFile >> "CfgWeapons" >> _weapon >> "ACE_Dispersion")) then {
        getNumber (configFile >> "CfgWeapons" >> _weapon >> "ACE_Dispersion");
    } else {
        1;
    };
    private _slowdownFactor = if (isNumber (configFile >> "CfgWeapons" >> _weapon >> "ACE_SlowdownFactor")) then {
        getNumber (configFile >> "CfgWeapons" >> _weapon >> "ACE_SlowdownFactor");
    } else {
        1;
    };
    private _jamChance = if (isNumber (configFile >> "CfgWeapons" >> _weapon >> "ACE_MRBS")) then {
        getNumber (configFile >> "CfgWeapons" >> _weapon >> "ACE_MRBS");
    } else {
        3000;
    };
    _jamChance = if (_jamChance == 0) then {0} else {1/_jamChance};

    _weaponData = [_dispersion, _slowdownFactor, _jamChance];
    TRACE_2("building cache",_weapon,_weaponData);
    GVAR(weaponInfoCache) setVariable [_weapon, _weaponData];
};
_weaponData params ["_dispersion", "_slowdownFactor", "_jamChance"];
TRACE_4("weapon data from cache",_weapon,_dispersion,_slowdownFactor,_jamChance);

// Dispersion and bullet slow down
if (GVAR(overheatingDispersion)) then {
    // Exit if GVAR(pseudoRandomList) isn't synced yet
    if (isNil QGVAR(pseudoRandomList)) exitWith {ACE_LOGERROR("No pseudoRandomList sync");};

    //Dispersion: 0 mils @ 0°C, 0.5 mils @ 333°C, 2.2 mils @ 666°C, 5 mils at 1000°C
    _dispersion = _dispersion * 0.28125 * (_scaledTemperature^2);

    _slowdownFactor = _slowdownFactor * linearConversion [0.666, 1, _scaledTemperature, 0, -0.1, true];

    // Get the pseudo random values for dispersion from the remaining ammo count
    (GVAR(pseudoRandomList) select ((_unit ammo _weapon) mod (count GVAR(pseudoRandomList)))) params ["_dispersionX", "_dispersionY"];

    TRACE_4("change",_dispersion,_slowdownFactor,_dispersionX,_dispersionY);

    TRACE_PROJECTILE_INFO(_projectile);
    [_projectile, _dispersionX * _dispersion, _dispersionY * _dispersion, _slowdownFactor * vectorMagnitude (velocity _projectile)] call EFUNC(common,changeProjectileDirection);
    TRACE_PROJECTILE_INFO(_projectile);
};


// ------  LOCAL AND NEARBY PLAYERS DEPENDING ON SETTINGS ------------
// Particle effects only apply to the local player and, depending on settings, to other nearby players
if (_unit != ACE_player && (!GVAR(showParticleEffectsForEveryone) || {_unit distance ACE_player > 20})) exitWith {
    END_COUNTER(firedEH);
};

//Particle Effects:
if (GVAR(showParticleEffects) && {(ACE_time > ((_unit getVariable [QGVAR(lastDrop), -1000]) + 0.40)) && {_scaledTemperature > 0.1}}) then {
    _unit setVariable [QGVAR(lastDrop), ACE_time];

    private _direction = (_unit weaponDirection _weapon) vectorMultiply 0.25;
    private _position = (position _projectile) vectorAdd (_direction vectorMultiply (4*(random 0.30)));

    // Refract SFX, beginning at temp 100°C and maxs out at 500°C
    private _intensity = linearConversion [0.1, 0.5, _scaledTemperature, 0, 1, true];
    TRACE_3("refract",_direction,_position,_intensity);
    if (_intensity > 0) then {
        drop [
        "\A3\data_f\ParticleEffects\Universal\Refract", "", "Billboard", 10, 2, _position, _direction, 0, 1.2, 1.0,
        0.1, [0.10,0.25], [[0.6,0.6,0.6,0.3*_intensity],[0.2,0.2,0.2,0.05*_intensity]], [0,1], 0.1, 0.05, "", "", ""];
    };
    // Smoke SFX, beginning at temp 150°C
    private _intensity = linearConversion [0.15, 1, _scaledTemperature, 0, 1, true];
    TRACE_3("smoke",_direction,_position,_intensity);
    if (_intensity > 0) then {
        drop [
        ["\A3\data_f\ParticleEffects\Universal\Universal", 16, 12, 1, 16], "", "Billboard", 10, 1.2, _position,
        [0,0,0.15], 100 + random 80, 1.275, 1, 0.025, [0.15,0.43], [[0.6,0.6,0.6,0.5*_intensity],[0.2,0.2,0.2,0.15*_intensity]],
        [0,1], 1, 0.04, "", "", ""];
    };
};

// ------  LOCAL PLAYER ONLY ------------
// Only compute jamming for the local player
if (_unit != ACE_player) exitWith {END_COUNTER(firedEH);};

_jamChance = _jamChance * ([[0.5, 1.5, 7.5, 37.5], 3 * _scaledTemperature] call EFUNC(common,interpolateFromArray));

// increase jam chance on dusty grounds if prone (and at ground level)
if ((stance _unit == "PRONE") && {((getPosATL _unit) select 2) < 1}) then {
    private _surface = configFile >> "CfgSurfaces" >> ((surfaceType getPosASL _unit) select [1]);
    if (isClass _surface) then {
        TRACE_1("dust",getNumber (_surface >> "dust"));
        _jamChance = _jamChance + (getNumber (_surface >> "dust")) * _jamChance;
    };
};

TRACE_3("check for random jam",_unit,_weapon,_jamChance);
if ((random 1) < _jamChance) then {
    [_unit, _weapon] call FUNC(jamWeapon);
};

END_COUNTER(firedEH);
