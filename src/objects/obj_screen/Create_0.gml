screenX = 0;
screenY = 0;
screenW = 320;
screenH = 240;
screenScale = 2;
//create a surface for the screen to be drawn on
screen = surface_create(screenW, screenH);
//if the gpu doesn't support surfaces, revert back to viewports
if (screen == -1) { instance_destroy(); exit; }

//local variables
time = 0;
started = true;

//debug only variables
debugMessage = "";

scr_start()

//read (or write) input data
ini_open("config.ini");
if (!file_exists("config.ini")) {
	//game
	ini_write_real("GAME", "FULLSCREEN", 0);
	//keyboard
    ini_write_real("CONTROL_KEYBOARD", "0", ord("C"));
    ini_write_real("CONTROL_KEYBOARD", "1", ord("V"));
    ini_write_real("CONTROL_KEYBOARD", "2", ord("B"));
    ini_write_real("CONTROL_KEYBOARD", "3", ord("N"));
    ini_write_real("CONTROL_KEYBOARD", "4", ord("M"));
    ini_write_real("CONTROL_KEYBOARD", "5", vk_up);
    ini_write_real("CONTROL_KEYBOARD", "6", vk_down);
    ini_write_real("CONTROL_KEYBOARD", "7", vk_left);
    ini_write_real("CONTROL_KEYBOARD", "8", vk_right);
    ini_write_real("CONTROL_KEYBOARD", "9", ord("Z"));
    ini_write_real("CONTROL_KEYBOARD", "10", ord("X"));
    ini_write_real("CONTROL_KEYBOARD", "11", ord("C"));
    ini_write_real("CONTROL_KEYBOARD", "12", vk_escape);
	//gamepad
	//(not yet)
}
for (var i = 0; i < 24; i++) {
	global.buttonMapKeyboard[i] = ini_read_real("CONTROL_KEYBOARD", string(i), 0);
}
ini_close();

room_goto_next();