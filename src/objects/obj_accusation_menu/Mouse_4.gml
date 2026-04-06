if (global.accusation_level == 0 && mouse_check_button_pressed(mb_left) && position_meeting(mouse_x, mouse_y, op2)) {
	show_debug_message("correct1")
	if (global.accusation_level == 1 && mouse_check_button_pressed(mb_left) && position_meeting(mouse_x, mouse_y, op1)) {
		show_debug_message("correct2")
		if (global.accusation_level == 2 && mouse_check_button_pressed(mb_left) && position_meeting(mouse_x, mouse_y, op3)) {
			show_debug_message("correct3")
			global.game_win = 1; // yippee!!
		}
	}
}