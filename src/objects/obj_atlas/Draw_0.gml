draw_self();

if (global.debug) {
	draw_set_font(fnt_main);
	if (button_held(KEY.CONFIRM)) {
		draw_set_color(c_red);
		switch(global.facing) {
			case 0: draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom + intextend, true); break;
			case 1: draw_rectangle(bbox_left, bbox_top, bbox_right + intextend, bbox_bottom, true); break;
			case 2: draw_rectangle(bbox_left, bbox_top - intextend, bbox_right, bbox_bottom, true); break;
			case 3: draw_rectangle(bbox_left - intextend, bbox_top, bbox_right, bbox_bottom, true); break;
		}
		draw_set_color(c_white);
	}
}
