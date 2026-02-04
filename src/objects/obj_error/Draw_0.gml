draw_self();

if ((showError && error != "") || global.debug) {
	draw_set_font(fnt_main);
	draw_set_halign(fa_center);
	draw_text_transformed(room_width/2, 30, error, 0.5, 0.5, 0);
	draw_set_font(fnt_mainb);
	draw_text_transformed(room_width/2, 200, "Press the CONFIRM key\nto restart.", 0.5, 0.5, 0);
	draw_set_halign(fa_left);
}

if (keyboard_check_pressed(vk_tab)) {
	showError = !showError;
}

if (button_pressed(KEY.CONFIRM)) {
	var params = "";
	var count = parameter_count();
	for (var i = 0; i < count; i++) {
		if (parameter_string(i) != "-error") {
			params += parameter_string(i) + " ";
		} else {
			i++;
		}
	}
	global.playingsong.free();
	//print("params: " + string(params));
		
	game_change(".", params);
}