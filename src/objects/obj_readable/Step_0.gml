scr_debug_visible();

if (interact == 1) {
	event_user(0); //children of this object can put their text here
	global.txr = 4;
	writer = instance_create(0, 0, obj_dialoguer);
	global.action = 1;
	interact = 2;
}

if (interact == 2 && !instance_exists(writer)) {
	interact = 3;
	alarm[3] = 3; //buffer a little time until resetting interact
}