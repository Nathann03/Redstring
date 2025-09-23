time++;

if (keyboard_check_pressed(vk_f4)) {
	window_set_fullscreen(!window_get_fullscreen())
}

if (global.debug) {
	if (keyboard_check_pressed(024)) room_goto_next();  //add
	if (keyboard_check_pressed(109)) room_goto_next(); //minus
}

if (keyboard_check(vk_escape)) {
	quitmod++;
	if (quitmod > fps * 3) game_end();
} else { if (quitmod > 0) quitmod -= 6; };