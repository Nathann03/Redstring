draw_set_font(fnt_main);
if (global.debug and showDebugText)
{
	draw_set_color(c_white);
	draw_fps(10, 10, false);
	draw_text(10, 40, "Redstring " + VERSION + " (" + string(SAVE_FILE_VERSION) + ")");
	draw_text(10, 70, room_get_name(room) + " (" + string(real(room)) + ")");
}

var sec = (quitmod/60);
draw_set_alpha(clamp(sec,0,0.6));
draw_set_color(c_black);
draw_rectangle(0,0,640,380,false);
draw_set_color(c_white);
draw_set_alpha(sec);
var quitmsg = "QUITTING";
if (quitmod > 030) quitmsg = "QUITTING."
if (quitmod > 060) quitmsg = "QUITTING.."
if (quitmod > 090) quitmsg = "QUITTING.."
if (quitmod > 120) quitmsg = "QUITTING..."
draw_set_valign(fa_middle);
draw_text(256, 240, quitmsg);
draw_set_valign(fa_top);
draw_set_alpha(1);