var n, xx, yy;
xx = writex;
yy = writey;

if (input == "") {
	draw_set_alpha(0.4)
	draw_text(xx, yy, "Begin typing to ask a question...");
	draw_text(xx + 170, yy + 64, "...or press 'Enter' to close.");
} else {
	draw_set_alpha(1)
	draw_text_ext(xx, yy, input, vspacing, 516);
}