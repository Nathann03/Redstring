switch(global.facing) {
	case 0: sprite_index = spr_atlasd; break;
	case 1: sprite_index = spr_atlasr; break;
	case 2: sprite_index = spr_atlasu; break;
	case 3: sprite_index = spr_atlasl; break;
}

if (movement) {
	moving = 0;
	mx = 0;
	my = 0;
	if (button_held(KEY.DOWN)) {
		moving = true;
		global.facing = 0;
		my = moveSpeed;
	}
	if (button_held(KEY.RIGHT)) {
		moving = true;
		global.facing = 1;
		mx = moveSpeed;
	}
	if (button_held(KEY.UP)) {
		moving = true;
		global.facing = 2;
		my = -moveSpeed;
	}
	if (button_held(KEY.LEFT)) {
		moving = true;
		global.facing = 3;
		mx = -moveSpeed;
	}
	x += mx;
	y += my;
}
//check if we're interacting with something
if (button_pressed(KEY.CONFIRM)) event_user(0);

if (cutscene) {
	//don't do anything
} else if (moving) {
	image_index += imageSpeed;
} else {
	image_index = 0;
}