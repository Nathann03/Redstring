//local variables
time = 0;
started = true;
quitting = false;
quitmod = 0;
depth = -9999;

//debug only variables
debugMessage = "";
showDebugText = true;
d_SaveGamePNG = false;

scr_start();

if (global.debug) {
	instance_create(0, 0, obj_debugination);
}

#region error detection
var error = false;
if (parameter_count() > 0) {
	for (var i = 0; i < parameter_count(); i += 1) {
		params[i] = parameter_string(i + 1);
		if (params[i] == "-error") {
			error = i;
		}
	}
}
if (error != false) {
	global.exf = params[error + 1]; //read exception file
	room_goto(room_error);
	return;
}
#endregion

if (room != room_start) show_error("Somehow, you went back to the initalization room.", 0);

room_goto_next();