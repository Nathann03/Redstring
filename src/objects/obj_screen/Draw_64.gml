if (global.debug and showDebugText)
{
	draw_set_color(c_white);
	draw_fps(10, 10, true);
	draw_text(10, 40, "Redstring " + VERSION + " (" + string(SAVE_FILE_VERSION) + ")");
}