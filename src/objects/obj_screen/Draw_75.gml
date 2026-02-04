//saving the screen in the draw gui end event gives conssitent results across all platforms.
if (d_SaveGamePNG) {
	d_SaveGamePNG = false;
	var path = ($"screenshots/{string(current_year)}-{string(current_month)}-{string(current_day)}_{string(current_hour)}-{string(current_minute)}-{string(current_second)}.PNG");
	screen_save(path);
	print($"Saved screenshot as {string_replace_all(path, "screenshots/", "")}");
}