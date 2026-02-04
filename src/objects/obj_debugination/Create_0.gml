//winwin only supports windows as of now :(
if (os_type != os_windows) { print("Failed to make debug window. (windows only!)"); instance_destroy(); return; }

var config = new winwin_config();
config.caption = "NJR Debugination-Type Software";
config.resize = true;
config.close_button = 2;
config.thread = true;
//config.per_pixel_alpha = true
//config.kind = winwin_kind_tool;
extra = winwin_create(window_get_x() + window_get_width(), window_get_y(), 600, window_get_height(), config);
winwin_set_clickthrough(extra, false); 
extra.key_list = ds_list_create();	
extra.show_in = 0;
extra.last_caption = "";

msgcount = 0;
maxmsg = 28;
d_Message = array_create(maxmsg, "");
input = "";
consoleActive = false;
cursorBlink = 30;
cursorVisible = false;
testingInternet = false;
canInput = true;
httpRequest = -1;
httpReqURL = "";
httpReqStartTime = 0;
alarm[0] = 30;