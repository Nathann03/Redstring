function scr_start() {
	// constants
	#macro VERSION "rd20260405" // rd-year-month-day-revision
	#macro SAVE_FILE_VERSION 1
	
	#macro KEY_UP 5
	#macro KEY_DOWN 6
	#macro KEY_LEFT 7
	#macro KEY_RIGHT 8
	#macro KEY_BT1 9
	#macro KEY_BT2 10
	#macro KEY_BT3 11
	
	#macro c_select #8B5CF6
	
	// not constants
	global.action = 0;
	global.facing = 0;
	global.time = 0;
	global.txr = 1;
	global.language = "en";
	
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
	
	global.evid_collected = []; // array to track collected evidence
	global.evid_clicked = 0 // for the evidence info in the GUI
	global.in_menu = 0; // tracks whether a GUI is open (or if the player should not be able to move)
	global.ai_mode = 1; // 0 = NPC dialogue is scripted, 1 = NPC dialogue is AI generated
	global.player_msg = ""; // question the player asks in plain text
	global.secrets = ""; // access token is stored here
	global.npc_name = "" // most recent NPC interacted with
	global.accusation_level = 0; // tracks the progression of the accusation menu
	global.game_win = 0; // self explanatory
	
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
		global.inputPressed[i] = false;
		global.inputHeld[i] = false;
	}
	
	global.inputMapKB[KEY.CONFIRM] = vk_enter;
	global.inputMapKB[KEY.CANCEL] = vk_shift;
	global.inputMapKB[KEY.MENU] = vk_control;
	global.inputMapKB[KEY.UP] = vk_up;
	global.inputMapKB[KEY.DOWN] = vk_down;
	global.inputMapKB[KEY.LEFT] = vk_left;
	global.inputMapKB[KEY.RIGHT] = vk_right;
	
	global.debug = false; // causes problems w/ text input if set to true
	
	draw_set_color(c_white);
	draw_set_font(fnt_main);
} 