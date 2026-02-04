spriteIndex += spriteSpeed;

if (createdWriter) {
	if (button_pressed(KEY.CANCEL)) {
		with (writer) event_user(1);
	}
	if (!instance_exists(writer)) goin = true;
}

if (goout) {
	if (surfHeight < 125) {
		surfHeight += 8;
	} else if (!createdWriter) {
		createdWriter = true;
		surfHeight = 125;
		goout = false;
		xx = camerax();
		yy = cameray();
		wx = xx + 35;
		wy = yy + 330;
		writer = instance_create(wx, wy, obj_writer);
	}
} else if (goin) {
	if (surfHeight > 2) {
		surfHeight -= 8;
	} else {
		instance_destroy();
	}
}