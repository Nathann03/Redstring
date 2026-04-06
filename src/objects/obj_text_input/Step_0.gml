var typed = keyboard_string;
if (typed != "" && string_height_ext(input+typed, vspacing, 516) < 120) {
	input += typed;
	keyboard_string = "";
} else {
	keyboard_string = "";
}

if (keyboard_check_pressed(vk_backspace) && input != "") {
	input = string_delete(input, string_length(input), 1);
}

if (keyboard_check_pressed(vk_enter) && input != "") {
	global.player_msg = input;
	global.in_menu = 0;
	instance_create_depth(0, 0, 0, obj_ai_interface);
	instance_destroy();
} else if (keyboard_check_pressed(vk_enter) && input == "") {
	global.in_menu = 0;
	global.npc_name = "";
	instance_destroy();
}