var gamepad = async_load[? "pad_index"];

switch(async_load[? "event_type"]) {
	case "gamepad discovered":
		global.gamepad = gamepad;
		printf("controller ({:1}) connected! (id: {:2})", gamepad_get_description(gamepad), gamepad);
		break;
	case "gamepad lost":
		printf("controller disconnected");
		global.gamepad = -1;
		break;
}