/*
  # HEADER #
	Script: 		Common\Functions\Common_RearmVehicle.sqf
	Alias:			CTI_CO_FNC_RearmVehicle
	Description:	Rearm a vehicle and it's turrets
	Author: 		Benny
	Creation Date:	19-09-2013
	Revision Date:	14-10-2013

  # PARAMETERS #
    0	[Object]: The vehicle
    1	[Side]: The side of the vehicle

  # RETURNED VALUE #
	None

  # SYNTAX #
	[VEHICLE, SIDE] call CTI_CO_FNC_RearmVehicle

  # DEPENDENCIES #
	Common Function: CTI_CO_FNC_SanitizeAircraft
	Common Function: CTI_CO_FNC_SanitizeArtillery

  # EXAMPLE #
    [vehicle player, CTI_P_SideJoined] call CTI_CO_FNC_RearmVehicle;
	  -> Rearm the player vehicle of the player
*/

private ["_side", "_type", "_vehicle"];

_vehicle = _this select 0;
_side = _this select 1;
_type = typeOf _vehicle;
_t_side = if (typeName _side == "SCALAR") then {(_side call CTI_CO_FNC_GetSideFromID)} else {_side};

//Add Data link
if(count ((_t_side) call CTI_CO_FNC_GetSideUpgrades) >= CTI_UPGRADE_DATA) then {
if(((_t_side) call CTI_CO_FNC_GetSideUpgrades) select CTI_UPGRADE_DATA == 1) then {
	_vehicle setVehicleReportOwnPosition true;
	_vehicle setVehicleReportRemoteTargets true;
	_vehicle setVehicleReceiveRemoteTargets true;
};};

// Fix for air vehicles ... uses sanatise script to clean up afterwards
//enable for && (!(_vehicle isKindOf "O_Plane_Fighter_02_F")) && (!(_vehicle isKindOf "B_Plane_Fighter_01_F")) && (!(_vehicle isKindOf "I_Plane_Fighter_04_F"))
if (	(((typeOf _vehicle) == "O_APC_Tracked_02_AA_F") 
		|| ((typeOf _vehicle) == "B_APC_Tracked_01_AA_F")
		|| _vehicle isKindOf "Air") 
		&& (missionNamespace getVariable "CTI_AC_ENABLED")>0
		&& CTI_isCLient) then
{
	_loadout = _vehicle getVariable "CTI_AC_AIRCRAFT_LOADOUT_MOUNTED";
	if(!isNil "_loadout") then {
	
		_vehicle call CTI_AC_PURGE_ALL_WEAPONS;
		[_vehicle, _t_side] call CTI_AC_REFRESH_LOADOUT_ON_MOUNTED;
		//Not needed if loadout_mounted if (_vehicle isKindOf "Air") then {[_vehicle, _side] call CTI_CO_FNC_SanitizeAircraft};
	};
} else {

	//--- Driver
	{_vehicle removeMagazineTurret [_x, [-1]];} forEach (getArray(configFile >> "CfgVehicles" >> _type >> "magazines"));
	{_vehicle addMagazineTurret [_x, [-1]]} forEach (getArray(configFile >> "CfgVehicles" >> _type >> "magazines"));
	
	//--- Turrets
	if (!(_vehicle isKindOf "B_SAM_System_01_F" || _vehicle isKindOf "B_SAM_System_02_F" || _vehicle isKindOf "B_AAA_System_01_F")) then {
	_config = configFile >> "CfgVehicles" >> _type >> "turrets";
	for '_i' from 0 to (count _config)-1 do {
		_turret_main = _config select _i;
		_config_sub = _turret_main >> "turrets";
		{_vehicle removeMagazineTurret [_x, [_i]];} forEach (getArray(_turret_main >> "magazines"));
		{ _vehicle addMagazineTurret [_x, [_i]]} forEach (getArray(_turret_main >> "magazines"));
		for '_j' from 0 to (count _config_sub) -1 do {
			_turret_sub = _config_sub select _j;
			{_vehicle removeMagazineTurret [_x, [_i, _j]];} forEach (getArray(_turret_sub >> "magazines"));
			{_vehicle addMagazineTurret [_x, [_i, _j]];} forEach (getArray(_turret_sub >> "magazines"));
		};
	  };
	};

	//--- Authorize the air loadout depending on the parameters set
	//enabled pylons again: && (!(_vehicle isKindOf "O_Plane_Fighter_02_F")) && (!(_vehicle isKindOf "B_Plane_Fighter_01_F")) && (!(_vehicle isKindOf "I_Plane_Fighter_04_F"))
	if ((_vehicle isKindOf "Air")) then {[_vehicle, _side] call CTI_CO_FNC_SanitizeAircraft};

	//--- Sanitize the artillery loadout, mines may lag the server for instance
	if (CTI_ARTILLERY_FILTER == 1) then {if (typeOf _vehicle in (missionNamespace getVariable ["CTI_ARTILLERY", []])) then {(_vehicle) call CTI_CO_FNC_SanitizeArtillery}};
	
	
	if (_vehicle isKindOf "tank" || _vehicle isKindOf "Wheeled_APC_F") then {
		_ammo=if (! (count ((_side) call CTI_CO_FNC_GetSideUpgrades) == 0)) then {2+2*(((_side) call CTI_CO_FNC_GetSideUpgrades) select CTI_UPGRADE_TRA)} else {2};
		_vehicle setVariable ["TROPHY_time_l",time-10000,true];
		_vehicle setVariable ["TROPHY_time_r",time-10000,true];
		_vehicle setVariable ["TROPHY_ammo_l",ceil(_ammo/2),true];
		_vehicle setVariable ["TROPHY_ammo_r",ceil(_ammo/2),true];

	};
	
	if (_vehicle isKindOf "B_SAM_System_01_F" || _vehicle isKindOf "B_SAM_System_02_F" || _vehicle isKindOf "B_AAA_System_01_F") then {
		["SERVER", "Request_Locality", [_vehicle,player]] call CTI_CO_FNC_NetSend;
		if (local _vehicle) then {
			if (_vehicle isKindOf "B_SAM_System_01_F") then {
				_vehicle removeMagazineGlobal "magazine_Missile_rim116_x21";
				_vehicle addMagazineGlobal "magazine_Missile_rim116_x21";
			};
			if (_vehicle isKindOf "B_SAM_System_02_F") then {
				_vehicle removeMagazineGlobal "magazine_Missile_rim162_x8";
				_vehicle addMagazineGlobal "magazine_Missile_rim162_x8";
			};
			if (_vehicle isKindOf "B_AAA_System_01_F") then {
				_vehicle removeMagazineGlobal "magazine_Cannon_Phalanx_x1550";
				_vehicle addMagazineGlobal "magazine_Cannon_Phalanx_x1550";
			};
		};
	};
};