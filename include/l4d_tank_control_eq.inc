#if defined _l4d_tank_control_eq_included_
  #endinput
#endif
#define _l4d_tank_control_eq_included_

forward Action TankControlEQ_OnChooseTank();

forward void TankControlEQ_OnTankGiven(const char[] steamId);

forward void TankControlEQ_OnTankControlReset();

native void TankControlEQ_SetTank(const char[] steamId);

native ArrayList TankControlEQ_GetWhosHadTank();

native ArrayList TankControlEQ_GetWhosNotHadTank();

native void TankControlEQ_ClearWhosHadTank();

native ArrayList TankControlEQ_GetTankPool();

public SharedPlugin __pl_l4d_tank_control_eq = 
{
    name = "l4d_tank_control_eq",
    file = "l4d_tank_control_eq.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d_tank_control_eq_SetNTVOptional()
{
    MarkNativeAsOptional("TankControlEQ_SetTank");
    MarkNativeAsOptional("TankControlEQ_GetWhosHadTank");
    MarkNativeAsOptional("TankControlEQ_GetWhosNotHadTank");
    MarkNativeAsOptional("TankControlEQ_ClearWhosHadTank");
    MarkNativeAsOptional("TankControlEQ_GetTankPool");
}
#endif