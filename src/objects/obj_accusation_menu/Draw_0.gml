image_index = global.accusation_level
depth = -11

if (global.accusation_level == 3 && global.game_win == 0) {
	instance_destroy(op1)
	instance_destroy(op2)
	instance_destroy(op3)
	instance_destroy(op4)
	draw_text(90,190,"Not Quite...")
} else if (global.accusation_level == 3 && global.game_win == 1) {
	instance_destroy(op1)
	instance_destroy(op2)
	instance_destroy(op3)
	instance_destroy(op4)
	draw_text(90,190,"You Win!")
}

draw_self();