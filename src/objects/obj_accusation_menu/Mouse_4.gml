if (global.accusation_level == 0 && global.game_win = 0 && mouse_check_button_pressed(mb_left) && position_meeting(mouse_x, mouse_y, op2)) {
	show_debug_message("correct 1")
	global.game_win = 1;
	
}

if (global.accusation_level == 1 && global.game_win = 1 && mouse_check_button_pressed(mb_left) && position_meeting(mouse_x, mouse_y, op1)) {
	show_debug_message("correct 2")
	global.game_win = 2;
		
}

if (global.accusation_level == 2 && global.game_win = 2 && mouse_check_button_pressed(mb_left) && position_meeting(mouse_x, mouse_y, op3)) {
	show_debug_message("correct 3")
	global.game_win = 3; // yippee!!
}