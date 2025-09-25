switch(global.facing) {
	case 0: sprite_index = spr_atlasd; break;
	case 1: sprite_index = spr_atlasd; break;
	case 2: sprite_index = spr_atlasd; break;
	case 3: sprite_index = spr_atlasd; break;
}

if (movement) {
	moving = 0;
	mx = 0;
	my = 0;
	if (down_held()) {
		moving = true;
		global.facing = 0;
		my = moveSpeed;
	}
	if (right_held()) {
		moving = true;
		global.facing = 1;
		mx = moveSpeed;
	}
	if (up_held()) {
		moving = true;
		global.facing = 2;
		my = -moveSpeed;
	}
	if (left_held()) {
		moving = true;
		global.facing = 3;
		mx = -moveSpeed;
	}
	x += mx;
	y += my;
}
//check if we're interacting with something
if (bt1_pressed()) event_user(0);

if (cutscene) {
	//don't do anything
} else if (moving) {
	image_index += imageSpeed;
} else {
	image_index = 0;
}