selector_active = 1;

dest_room = "room_"; //room_get_name(room)
ss_width = surface_get_width(application_surface);
ss_height = surface_get_height(application_surface);
ss = sprite_create_from_surface(application_surface, 0, 0, ss_width, ss_height, false, false, 0, 0);
scale = min(window_get_width() / ss_width, window_get_height() / ss_height);
instance_deactivate_all(true);
instance_activate_object(obj_screen);
selector_initialized = 1;
hh = ss_height * scale;
ww = ss_width * scale;
keyboard_lastchar = "";
display_set_gui_size(ww, hh);
ds_list_clear(suggestions);
keyboard_clear(vk_f3);
image_alpha = 0;
exiting = 0;
update = 1;
