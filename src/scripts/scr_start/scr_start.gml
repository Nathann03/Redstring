function scr_start() {
	// constants
	#macro VERSION "2025918a" // year-month-day-revision
	#macro SAVE_FILE_VERSION 1
	#macro KEY_UP 5
	#macro KEY_DOWN 6
	#macro KEY_LEFT 7
	#macro KEY_RIGHT 8
	#macro KEY_BT1 9
	#macro KEY_BT2 10
	#macro KEY_BT3 11
	#macro c_select make_color_rgb(98, 255, 98)
	// not constants
	global.action = 0;
	global.facing = 0;
	global.txr = 1;
	
	for (var i = 0; i < 48; i++) {
		global.msg[i] = "%%";
	}
	
	global.debug = true;
	
	draw_set_color(c_white);
	draw_set_font(fnt_maintext);
} 