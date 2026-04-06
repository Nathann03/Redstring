function scr_getbuttonsprite(buttonID) {
	if (global.gamepad == -1) {
		printf("WARNING: trying to get a button sprite when no controller is connected ({:1})", buttonID);
		return spr_nothing;
	}
	var gamepadDesc = string_lower(gamepad_get_description(global.gamepad));
	var gamepad = "unknown";
	if (string_pos("xbox", gamepadDesc) || string_pos("xinput", gamepadDesc)) gamepad = "xbox";
	if (string_pos("playstation", gamepadDesc) || string_pos("dualshock", gamepadDesc)) gamepad = "playstation";
	if (string_pos("switch", gamepadDesc)) gamepad = "switch";
	
	if (buttonID == KEY.DOWN) {
		return spr_button_generic_D;
	}
	if (buttonID == KEY.RIGHT) {
		return spr_button_generic_R;
	}
	if (buttonID == KEY.UP) {
		return spr_button_generic_U;
	}
	if (buttonID == KEY.LEFT) {
		return spr_button_generic_L;
	}
	
	var button = noone;
	if (buttonID == KEY.CONFIRM) button = global.inputMapGP[KEY.CONFIRM];
	if (buttonID == KEY.CANCEL) button = global.inputMapGP[KEY.CANCEL];
	if (buttonID == KEY.MENU) button = global.inputMapGP[KEY.MENU];
	
	if (button == gp_face1) {
		if (gamepad == "xbox") return spr_button_xbox_A;
		if (gamepad == "playstation") return spr_button_playstation_cross;
		if (gamepad == "switch") return spr_button_switch_A;
	}
	if (button == gp_face2) {
		if (gamepad == "xbox") return spr_button_xbox_B;
		if (gamepad == "playstation") return spr_button_playstation_circle;
		if (gamepad == "switch") return spr_button_switch_B;
	}
	if (button == gp_face3) {
		if (gamepad == "xbox") return spr_button_xbox_X;
		if (gamepad == "playstation") return spr_button_playstation_triangle;
		if (gamepad == "switch") return spr_button_switch_X;
	}
	if (button == gp_face4) {
		if (gamepad == "xbox") return spr_button_xbox_Y;
		if (gamepad == "playstation") return spr_button_playstation_square;
		if (gamepad == "switch") return spr_button_switch_Y;
	}
	return spr_nothing;
}