//if the debug console is active, don't accept input. since ENTER is one of the interact keys, you can accidently press that while entering a command.
if (instance_exists(obj_debugination)) {if (obj_debugination.consoleActive) return;}

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
#endregion Input Manager

#region Debug
if (global.debug) {
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