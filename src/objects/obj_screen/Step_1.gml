#region Input
//if the debug console is active, don't accept input. since ENTER is one of the interact keys, you can accidently press that while entering a command.
if (instance_exists(obj_debugination)) {if (obj_debugination.consoleActive) return;}
for (var i = 0; i < KEY.COUNT; ++i) {
	global.inputPressedKB[i] = keyboard_check_pressed(global.inputMapKB[i]);
	global.inputHeldKB[i] = keyboard_check_direct(global.inputMapKB[i]);
}
global.inputPressedKB[KEY.CONFIRM] |= keyboard_check_pressed(ord("Z"));
global.inputHeldKB[KEY.CONFIRM] |= keyboard_check_direct(ord("Z"));
global.inputPressedKB[KEY.CANCEL] |= keyboard_check_pressed(ord("X"));
global.inputHeldKB[KEY.CANCEL] |= keyboard_check_direct(ord("X"));
global.inputPressedKB[KEY.MENU] |= keyboard_check_pressed(ord("C"));
global.inputHeldKB[KEY.MENU] |= keyboard_check_direct(ord("C"));
#endregion Input

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