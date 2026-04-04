switch(global.facing) {
	case 0: sprite_index = spr_playerd; break;
	case 1: sprite_index = spr_playerr; break;
	case 2: sprite_index = spr_playeru; break;
	case 3: sprite_index = spr_playerl; break;
}

if (movement) {
	moving = 0;
	mx = 0;
	my = 0;
	if (button_held(KEY.DOWN)) {
		moving = true;
		global.facing = 0;
		if (!place_meeting(x, y + moveSpeed, obj_collision)) my = moveSpeed;
	}
	if (button_held(KEY.RIGHT)) {
		moving = true;
		global.facing = 1;
		if (!place_meeting(x + moveSpeed, y, obj_collision)) mx = moveSpeed;
	}
	if (button_held(KEY.UP)) {
		moving = true;
		global.facing = 2;
		if (!place_meeting(x, y - moveSpeed, obj_collision)) my = -moveSpeed;
	}
	if (button_held(KEY.LEFT)) {
		moving = true;
		global.facing = 3;
		if (!place_meeting(x - moveSpeed, y, obj_collision)) mx = -moveSpeed;
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