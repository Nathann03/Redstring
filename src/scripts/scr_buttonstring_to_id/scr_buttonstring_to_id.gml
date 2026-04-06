function scr_buttonstring_to_id(buttonString) {
	if (buttonString == "Z") return KEY.CONFIRM;
	if (buttonString == "X") return KEY.CANCEL;
	if (buttonString == "C") return KEY.MENU;
	if (buttonString == "D") return KEY.DOWN;
	if (buttonString == "R") return KEY.RIGHT;
	if (buttonString == "U") return KEY.UP;
	if (buttonString == "L") return KEY.LEFT;
	return -1;
}