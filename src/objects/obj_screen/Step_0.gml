time++;

if (keyboard_check_pressed(vk_f4)) {
	window_set_fullscreen(!window_get_fullscreen())
}

if (global.debug) {
	if (keyboard_check_pressed(024)) room_goto_next();  //add
	if (keyboard_check_pressed(109)) room_goto_next(); //minus
}