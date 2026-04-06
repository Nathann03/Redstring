//spriteIndex += spriteSpeed;

if (createdWriter) {
	if (button_pressed(KEY.CANCEL)) {
		with (writer) event_user(1);
	}
	if (!instance_exists(writer)) goin = true;
}

if (goout) {
	if (surfHeight < (sprite_get_height(textbox_style)*2)+5) {
		surfHeight += 8;
		alpha += 0.05;
	} else if (!createdWriter) {
		createdWriter = true;
		surfHeight = (sprite_get_height(textbox_style)*2)+5;
		goout = false;
		xx = camerax();
		yy = cameray();
		wx = xx + 35;
		wy = yy + 330;
		if (global.in_menu == 0) {
			writer = instance_create(wx, wy, obj_writer);
		} else {
			writer = instance_create(wx, wy, obj_text_input);
		}
	}
} else if (goin) {
	if (surfHeight > 2) {
		surfHeight -= 8;
		alpha -= 0.05;
	} else {
		instance_destroy();
	}
}