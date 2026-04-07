//if the debug console is active, don't accept input. since ENTER is one of the interact keys, you can accidently press that while entering a command.
if (instance_exists(obj_debugination)) {if (obj_debugination.consoleActive) return;}

// if player is in a menu, don't accept input
if (global.in_menu > 0) return;

#region Input Manager
for (var i = 0; i < KEY.COUNT; i++) {
	global.inputPressed[i] = keyboard_check_pressed(global.inputMapKB[i]);
	global.inputHeld[i] = keyboard_check_direct(global.inputMapKB[i]);
}
global.inputPressed[KEY.CONFIRM] |= keyboard_check_pressed(ord("Z"));
global.inputHeld[KEY.CONFIRM] |= keyboard_check_direct(ord("Z"));
global.inputPressed[KEY.CANCEL] |= keyboard_check_pressed(ord("X"));
global.inputHeld[KEY.CANCEL] |= keyboard_check_direct(ord("X"));
global.inputPressed[KEY.MENU] |= keyboard_check_pressed(ord("C"));
global.inputHeld[KEY.MENU] |= keyboard_check_direct(ord("C"));
if (global.gamepad != -1) {
	for (var i = 0; i < KEY.COUNT; i++) {
		global.inputPressed[i] |= gamepad_button_check_pressed(global.gamepad, global.inputMapGP[i]);
		global.inputHeld[i] |= gamepad_button_check(global.gamepad, global.inputMapGP[i]);
	}
	global.inputHeld[KEY.UP] |= (gamepad_axis_value(global.gamepad, gp_axislv) < -0.25);
	global.inputHeld[KEY.DOWN] |= (gamepad_axis_value(global.gamepad, gp_axislv) > 0.25);
	global.inputHeld[KEY.LEFT] |= (gamepad_axis_value(global.gamepad, gp_axislh) < -0.25);
	global.inputHeld[KEY.RIGHT] |= (gamepad_axis_value(global.gamepad, gp_axislh) > 0.25);
	global.inputPressed[KEY.UP] |= (gamepad_axis_value(global.gamepad, gp_axislv) < -0.25);
	global.inputPressed[KEY.DOWN] |= (gamepad_axis_value(global.gamepad, gp_axislv) > 0.25);
	global.inputPressed[KEY.LEFT] |= (gamepad_axis_value(global.gamepad, gp_axislh) < -0.25);
	global.inputPressed[KEY.RIGHT] |= (gamepad_axis_value(global.gamepad, gp_axislh) > 0.25);
	for (var i = KEY.UP; i <= KEY.RIGHT; i++) {
		if (global.inputPressed[i]) {
			if (!gamepadButtonPressed[i] || gamepadPressHoldTime[i] >= 15) {
				gamepadButtonPressed[i] = true;
			} else {
				global.inputPressed[i] = false;
				gamepadPressHoldTime[i]++;
			}
		} else {
			gamepadButtonPressed[i] = false;
			gamepadPressHoldTime[i] = 0;
		}
	}
}
#endregion Input Manager

#region Debug
if (global.debug || true) {
	if (keyboard_check_pressed(vk_f2)) {
		with(obj_roomselector) {
			if (!selector_active)
				event_user(0);
		}
	}
	if (keyboard_check_pressed(ord("Q"))) {
		show_debug_overlay(!is_debug_overlay_open(), true, ((window_get_fullscreen()) ? 2 : 1), 1);
	}
	if (keyboard_check_pressed(ord("K"))) { //kapture!!
		d_SaveGamePNG = true;
	}
}
#endregion Debug