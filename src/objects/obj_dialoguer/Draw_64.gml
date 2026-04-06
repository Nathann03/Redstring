draw_sprite_ext(npc_profile, 1, 20, -34, 2, 2, 0, c_white, alpha);

if (!surface_exists(surf)) surf = surface_create(surfWidth, surfHeight);
if (surfHeight < 4) return;
surface_resize(surf, surfWidth, surfHeight);
surface_set_target(surf);
// draw_sprite_ext(spr_dialoguer, spriteIndex, 0, 0, surfWidth/16, surfHeight/16, 0, c_white, 1);
draw_sprite_ext(textbox_style, spriteIndex, 0, 0, 2, 2, 0, c_white, 1);
surface_reset_target();
draw_surface(surf, 20, (385-sprite_get_height(textbox_style)) + (abs(125/2) - surfHeight/2));

draw_set_font(fnt_mainb);
draw_text(surfWidth-132,(385-sprite_get_height(textbox_style)) + (abs(125/2) - surfHeight/2)+4,npc_name)