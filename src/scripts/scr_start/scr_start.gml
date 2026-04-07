function scr_start() {
	// constants
	 // rd-year-month-day-revision
	#macro VERSION "rd" + (string(date_get_year(GM_build_date)) + (date_get_month(GM_build_date) < 10 ? ("0" + string(date_get_month(GM_build_date))) : string(date_get_month(GM_build_date))) + (date_get_day(GM_build_date) < 10 ? ("0" + string(date_get_day(GM_build_date))) : string(date_get_day(GM_build_date))))
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
	global.entrance = 0;
	global.destination = -1;
	
	global.gamepad = -1;
	
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
	global.accuse_npc = ""; // for end cutscene
	global.accuse_evidence = 0; // for end cutscene
	global.accuse_location = 0; // for end cutscene
	
	enum AUDIO_PRIORITY {
		MASTER = 100,
		MUSIC = 50,
		SFX = 25,
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
		global.inputPressed[i] = false;
		global.inputHeld[i] = false;
		global.inputMapKB[i] = 0;
		global.inputMapGP[i] = 0;
	}
	
	global.inputMapKB[KEY.CONFIRM] = vk_enter;
	global.inputMapKB[KEY.CANCEL] = vk_shift;
	global.inputMapKB[KEY.MENU] = vk_control;
	global.inputMapKB[KEY.UP] = vk_up;
	global.inputMapKB[KEY.DOWN] = vk_down;
	global.inputMapKB[KEY.LEFT] = vk_left;
	global.inputMapKB[KEY.RIGHT] = vk_right;
	
	global.inputMapGP[KEY.CONFIRM] = gp_face1;
	global.inputMapGP[KEY.CANCEL] = gp_face2;
	global.inputMapGP[KEY.MENU] = gp_face3;
	global.inputMapGP[KEY.UP] = gp_padu;
	global.inputMapGP[KEY.DOWN] = gp_padd;
	global.inputMapGP[KEY.LEFT] = gp_padl;
	global.inputMapGP[KEY.RIGHT] = gp_padr;
	
	global.debug = false;
	
	draw_set_color(c_white);
	draw_set_font(fnt_main);
} 