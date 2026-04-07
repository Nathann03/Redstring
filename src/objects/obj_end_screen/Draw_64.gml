draw_self()

draw_set_font(fnt_mainb);

draw_set_color(#1A1A2E);
draw_rectangle(0, 0, room_width, room_height, false);
draw_set_color(#C5D8E1);
var win = (global.game_win == 3);


if (win) {
	draw_text_align(320,30,"=-=-= REDSTRING =-=-=");
	draw_text_align(320,95,"The End\nThanks for playing!");
	draw_text_align(320,200,"Faith Rider: Art and Narrative\nNathan Nguyen: AI/Backend Programming\nElias Weitfle: Game Programming\nNoah Rider: External Game Programming");
} else {
	draw_text_align(320,96,"Bad End");
	draw_text_align(320,160,"Your accusation doesn't match the evidence.\nThe lighthouse keeps its secrets.");
}

draw_set_color(#FFFFFF);

draw_sprite_ext(spr_lighthouse, 0, 306, 372, 2, 2, 0, c_white, 1);