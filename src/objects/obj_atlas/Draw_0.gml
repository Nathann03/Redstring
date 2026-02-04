draw_self();

if (global.debug) {
    //draw_set_font(fnt_small);
    //draw_text(x,y-30,"x: " + string(x));
    //draw_text(x,y-20,"y: " + string(y));
    //draw_text(x,y-10,"a: " + string(global.action));
    draw_set_font(fnt_main);
    if (button_held(KEY.CONFIRM)) {
		draw_set_color(make_color_rgb(98,0,0));
		draw_rectangle(bbox_left, bbox_bottom, bbox_right, bbox_bottom, true);
        draw_set_color(make_color_rgb(0,98,98));
        switch(global.facing) {
            case 0: draw_rectangle(bbox_left, bbox_bottom, bbox_right, bbox_bottom+intextend, true); break;
            case 1: draw_rectangle(bbox_right, bbox_top, bbox_right+intextend, bbox_bottom, true); break;
            case 2: draw_rectangle(bbox_left, bbox_top-intextend, bbox_right, bbox_top, true); break;
            case 3: draw_rectangle(bbox_left-intextend, bbox_top, bbox_left, bbox_bottom, true); break;
        }
        draw_set_color(c_white);
    }
}