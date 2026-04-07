if (global.accusation_level == 0 && mouse_check_button_pressed(mb_left) && position_meeting(mouse_x, mouse_y, op2)) {
	show_debug_message("correct 1")
	global.accuse_location = 1
	global.game_win++
	
}

if (global.accusation_level == 1 && mouse_check_button_pressed(mb_left) && position_meeting(mouse_x, mouse_y, op1)) {
	show_debug_message("correct 2")
	global.accuse_evidence = 1;
	global.game_win++
}

if (global.accusation_level == 2 && mouse_check_button_pressed(mb_left) && position_meeting(mouse_x, mouse_y, op3)) {
	show_debug_message("correct 3")
	global.npc_name = "yuki_tanaka"
	global.game_win++
}

// bad ending stuff
if (global.accusation_level == 2 && mouse_check_button_pressed(mb_left) && position_meeting(mouse_x, mouse_y, op1)) {
	global.npc_name = "riley_chen"
	global.game_win = 0
}
if (global.accusation_level == 2 && mouse_check_button_pressed(mb_left) && position_meeting(mouse_x, mouse_y, op2)) {
	global.npc_name = "james_okoye"
	global.game_win = 0
}
if (global.accusation_level == 2 && mouse_check_button_pressed(mb_left) && position_meeting(mouse_x, mouse_y, op4)) {
	global.npc_name = "catch_wallace"
	global.game_win = 0
}