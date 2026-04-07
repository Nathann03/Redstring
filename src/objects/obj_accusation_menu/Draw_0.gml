image_index = global.accusation_level
depth = -11

draw_set_font(fnt_mainb)

if (global.accusation_level == 3 && global.game_win < 3) {
	instance_destroy(op1)
	instance_destroy(op2)
	instance_destroy(op3)
	instance_destroy(op4)
	
	//draw_text(90,190,"Not Quite...")
	global.destination = 11;
	global.in_menu = 0;
	fader = instance_create(0, 0, obj_rfader);
	
} else if (global.accusation_level == 3 && global.game_win == 3) {
	instance_destroy(op1)
	instance_destroy(op2)
	instance_destroy(op3)
	instance_destroy(op4)
	
	//draw_text(105,190,"You Win!")
	global.destination = 11;
	global.in_menu = 0;
	fader = instance_create(0, 0, obj_rfader);
}

draw_self();