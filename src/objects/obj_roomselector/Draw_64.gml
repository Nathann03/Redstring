if (selector_active)
{
    if (sprite_exists(ss))
        draw_sprite_ext(ss, 0, xx, yy, scale, scale, 0, c_white, 1);
    
    draw_set_alpha(image_alpha / 2);
    draw_set_font(fnt);
    draw_set_color(c_black);
    draw_rectangle(xx, yy, xx + ww, yy + hh, false);
    draw_set_alpha(image_alpha);
    draw_set_halign(fa_center);
    
    if (num_suggestions < 1)
        draw_set_color(c_red);
    else
        draw_set_color(c_white);
    
    textx = xx + (ww / 2);
    texty = yy + (hh / 3);
    draw_text(textx, texty, dest_room);
    draw_set_color(c_white);
	
	if (show_cursor)
		draw_text(textx + (string_width(dest_room) / 2) + 2, texty, "|");
    
    texty += (string_height(dest_room + "|") + 3);
    draw_set_color(c_white);
    draw_rectangle(textx - (ww / 4), texty, textx + (ww / 4), texty + 3, false);
    texty += 6;
    
    for (i = 0; i < num_suggestions; i++)
    {
        max_selection = i + 1;
        name = ds_list_find_value(suggestions, i);
        
        if ((texty + string_height(name)) > (yy + hh))
        {
            max_selection--;
            i = num_suggestions;
        }
        else
        {
            if (i == selection)
                draw_set_color(c_yellow);
            else
                draw_set_color(c_white);
            
            draw_text(textx, texty, name);
            texty += (string_height(name) + 3);
        }
    }
    
    if (max_selection > num_suggestions)
        max_selection = num_suggestions;
    
    if (cursor_timer-- < 1)
    {
        cursor_timer = 30;
        show_cursor ^= 1;
    }
    
    draw_set_halign(fa_left);
    draw_set_color(c_white);
    results_str = "???";
    
    if (num_suggestions > 0)
        results_str = string(num_suggestions);
    else
        results_str = "No ";
    
    results_str += " result";
    
    if (num_suggestions != 1)
        results_str += "s";
    
    if (max_selection != num_suggestions)
        results_str += (" (" + string(max_selection) + " shown)");
    
    draw_text(xx + 10, yy + 10, results_str);
    casing = "sensitive";
    
    if (!case_sensitive)
        casing = "in" + casing;
    
    draw_text(xx + 10, yy + 13 + string_height(results_str), "Case-" + casing + " (toggle with Tab)");
    draw_set_alpha(1);
}
