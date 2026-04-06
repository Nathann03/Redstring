if (global.in_menu < 2 && global.action == 0 && mouse_check_button_pressed(mb_left) && position_meeting(mouse_x, mouse_y, id)) {
	global.in_menu = 2;
	if (button_id == 1) instance_create_depth(20, 20, -10, obj_evidence_menu);
	
	if (button_id == 3) instance_create_depth(40, 32, -10, obj_accusation_menu);
}