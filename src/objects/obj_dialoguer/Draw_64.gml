if (!surface_exists(surf)) surf = surface_create(surfWidth, surfHeight);
if (surfHeight < 4) return;
surface_resize(surf, surfWidth, surfHeight);
surface_set_target(surf);
// draw_sprite_ext(spr_dialoguer, spriteIndex, 0, 0, surfWidth/16, surfHeight/16, 0, c_white, 1);
draw_sprite_ext(spr_textbox, spriteIndex, 0, 0, 2, 2, 0, c_white, 1);
surface_reset_target();
draw_surface(surf, 20, 325 + (abs((125/2) - surfHeight/2)));