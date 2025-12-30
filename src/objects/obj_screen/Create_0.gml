//local variables
time = 0;
started = true;
quitting = false;
quitmod = 0;
depth = -9999;

//debug only variables
debugMessage = "";
showDebugText = true;

scr_start();

if (room != room_start) show_error("Somehow, you went back to the initalization room.", 0);

room_goto_next();