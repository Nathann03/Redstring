///@description goto next page
if (lock == 1) { //normal
	lock = 0;
	char = " ";
	strpos = 0;
	lineno = 0;
	xx = writex;
	yy = writey;
	alarm[0] = textspeed;
	text = global.msg[++pageno];
	originaltext = text;
	formatted = false;
	length = strlen(text);
	event_user(2);
	if (text == "%%") {
		instance_destroy();
	}
}