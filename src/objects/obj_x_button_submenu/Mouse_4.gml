if (global.in_menu < 4 && mouse_check_button_pressed(mb_left) && position_meeting(mouse_x, mouse_y, id)) {
	global.in_menu--;
	instance_destroy()
}