winwin_draw_begin(extra);
//winwin_set_chromakey(extra, c_black);
winwin_draw_clear(c_black);
draw_set_halign(fa_left);
draw_set_font(fnt_main);
draw_set_color(c_white);
var displayedMessages = min(msgcount, maxmsg);
var _height = string_height("Debugination console by Noah Rider");

for (var i = 0; i < array_length(d_Message); i++) {
	if (d_Message[i] != "") {
		draw_text_ex(10, 10 + (i * _height), d_Message[i], 8, 16, 0);
	}
}
draw_text_ex(10, 10 + (array_length(d_Message) * _height), $"> {(consoleActive) ? input : "(console disabled)"}", 8, 16, 0);
winwin_draw_end();