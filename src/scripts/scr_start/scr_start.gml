function scr_start() {
	// constants
	#macro VERSION "rd20251216" // rd-year-month-day-revision
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
	global.time = 0;
	global.txr = 1;
	
	global.settings = {
		audio: {
			volume: 0.75,
			volumeSFX: 0.75,
		},
		video: {
			border: {
				
			},
		},
	};
	
	for (var i = 0; i < 48; i++) {
		global.msg[i] = "%%";
	}
	
	//input
	enum KEY {
		FRET1,
		FRET2,
		FRET3,
		FRET4,
		FRET5,
		STRUM,
		UP,
		DOWN,
		LEFT,
		RIGHT,
		CONFIRM,
		CANCEL,
		MENU,
		COUNT,
	}
	
	for (var i = 0; i < KEY.COUNT; ++i) {
		global.inputPressedKB[i] = false;
		global.inputHeldKB[i] = false;
	}
	
	global.inputMapKB = ds_list_create();
	ds_list_add(global.inputMapKB, ord("C")); // FRET0
	ds_list_add(global.inputMapKB, ord("V")); // FRET1
	ds_list_add(global.inputMapKB, ord("B")); // FRET2
	ds_list_add(global.inputMapKB, ord("N")); // FRET3
	ds_list_add(global.inputMapKB, ord("M")); // FRET4
	ds_list_add(global.inputMapKB, vk_space); // STRUM
	ds_list_add(global.inputMapKB, vk_up); // UP
	ds_list_add(global.inputMapKB, vk_down); // DOWN
	ds_list_add(global.inputMapKB, vk_left); // LEFT
	ds_list_add(global.inputMapKB, vk_right); // RIGHT
	ds_list_add(global.inputMapKB, vk_enter); // CONFIRM
	ds_list_add(global.inputMapKB, vk_shift); // CANCEL
	ds_list_add(global.inputMapKB, vk_control); // MENU
	
	global.debug = true;
	
	draw_set_color(c_white);
	draw_set_font(fnt_maintext);
} 