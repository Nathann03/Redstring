draw_self()

draw_set_font(fnt_mainb);

if (global.game_win == 3) {
	draw_text(265,96,"The End");
	draw_text(175,160,"=-=-= REDSTRING =-=-=");
	draw_text(195,280,"Thanks for playing!");
} else {
	draw_text(265,96,"Bad End");
	draw_text(115,160,"The real killer is still out there.");
	if (global.accuse_npc != "yuki_tanaka") {
		draw_text(50,280,"And you put an innocent person in prison.");
	}
}
