function draw_fps(x, y, extended) {
	var fpsText, oldColor;
	fpsText = string(fps);
	oldColor = draw_get_color();
	if (extended) fpsText += " (" + string((fps/60)*100) + "%)";
	if (fps >=60) draw_set_color(make_color_rgb(255,215,0)); //gold
	if (fps < 60) draw_set_color(c_green);
	if (fps < 35) draw_set_color(c_yellow);
	if (fps < 20) draw_set_color(c_red);
	draw_text(x, y, fpsText);
	draw_set_color(oldColor);
}