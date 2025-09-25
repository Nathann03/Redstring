//draw the screen
if (surface_exists(screen) and draw_screen())
{
	surface_reset_target();
	draw_clear(0);
	//draw_set_blend_mode_ext(bm_one, bm_zero);
	draw_surface_stretched(screen,screenX,screenY,screenW*screenScale,screenH*screenScale);
	//draw_set_blend_mode(bm_normal);
	//screen_refresh();
}
