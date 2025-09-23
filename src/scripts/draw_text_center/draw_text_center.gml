function draw_text_center(x, y, string) {
	var oldAlign = draw_get_halign();
	draw_set_halign(fa_center);
	draw_text(x, y, string);
	draw_set_halign(oldAlign);
}