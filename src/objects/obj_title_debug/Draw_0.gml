tiler += 2
//draw_background_tiled_ext(bg_settings, -tiler, 0, 0.5, 0.5, make_color_hsv((tiler/2), 150, 255), 1)
//draw_set_color(c_atgreen)
//draw_rectangle_solid(110, 70, 130+string_width(option[1]), 85+(18*optionno))
//draw_set_color(c_black)
//draw_rectangle_solid(113, 73, 127+string_width(option[1]), 82+(18*optionno))
draw_set_font(fnt_maintext);
for (var i = 0; i < optionno; i++)
{
    if (selected == i) draw_set_color(c_select);
    draw_text(120, 80+(18*i), option[i]);
    draw_set_color(c_white);
}
draw_text(0, 220, "selected: " + string(selected));