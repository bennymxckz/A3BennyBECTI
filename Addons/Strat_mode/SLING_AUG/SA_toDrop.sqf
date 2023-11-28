#define para_alt 250
#define min_alt  1.5

_target = _this;


if (!(_target iskindof "Helicopter") || (isNull  (getSlingLoad _target) && count (attachedObjects _target) ==0)) exitwith {false};


_drop=objNull;
_attached=false;

if (count (attachedObjects _target) >=1) then {
	{
		if !(isNull _x ) then {
			_drop=_x;
			_attached=true;
		};
	} forEach (attachedObjects _target);

};
if !(isNull  (getSlingLoad _target)) then {_drop=getSlingLoad _target};

if(!(isNull _drop)) then {
	if (_attached) then {
		//temporarily disable object collision
		_drop disableCollisionWith _target;
		detach _drop;_drop enableRopeAttach true;
		_target enableRopeAttach true;
		_target setmass (_target getvariable "initial_mass");
		_target setcenterofmass (_target getvariable "initial_COM");

		[_target , _drop] spawn {
			params ["_target", "_drop"];
			sleep 2;
			_drop enableCollisionWith _target;
		};
	} else {{ropeDestroy _x;true}count (ropes _target);};
	playSound3D ["A3\Sounds_F\vehicles\air\noises\SL_rope_break_ext.wss",_target];
	[_drop,(side player),para_alt,min_alt] spawn SA_DROP;
} else {
//remove nullobj
detach _drop;
if (true) exitWith { false };
};
true;