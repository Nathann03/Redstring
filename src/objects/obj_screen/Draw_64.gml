if (global.debug and showDebugText)
{
	draw_set_color(c_white);
	draw_fps(10, 10, false);
	draw_text(10, 40, "Redstring " + VERSION + " (" + string(SAVE_FILE_VERSION) + ")");
	draw_text(10, 70, room_get_name(room) + " (" + string(real(room)) + ")");
}

var sec = (quitmod/fps);
draw_set_alpha(clamp(sec,0,0.6));
draw_set_color(c_black);
draw_rectangle(0,0,640,380,false);
draw_set_color(c_white);
draw_set_alpha(sec);
var quitmsg = "QUITTING";
if (quitmod > fps * 1) quitmsg = "QUITTING."
if (quitmod > fps * 2) quitmsg = "QUITTING.."
if (quitmod > fps * 3) quitmsg = "QUITTING.."
var sh = string_height("A");
draw_text(300, 240-(sh/2), quitmsg);
draw_set_alpha(1);