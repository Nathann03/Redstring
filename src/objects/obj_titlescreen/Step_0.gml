if (mouse_check_button_pressed(mb_left) && image_index == 0) {
	if (point_in_rectangle(mouse_x, mouse_y, 91, 136, 220, 170)) {
		room_goto_next();
	}
	if (point_in_rectangle(mouse_x, mouse_y, 91, 192, 220, 226)) {
		image_index = 1;
	}
}

if (image_index == 1 && keyboard_check_pressed(vk_escape)) image_index = 0;