if (instance_number(object_index) > 1)
{
    instance_destroy(id, false);
    exit;
}

selector_active = 0;
selector_initialized = 0;
suggestions = ds_list_create();
valid_chars = "abcdefghijklmnopqrstuvwxyz_0123456789";
num_suggestions = 0;
case_sensitive = 1;
max_selection = 0;
update_cursor = 1;
cursor_timer = 30;
show_cursor = 1;
image_alpha = 0;
selection = 0;
update = 1;
scale = 1;
fnt = fnt_mainb;
len = 0;
ss = -4;

i = 0;
while (room_exists(++i)) {
	room_names[i] = room_get_name(i) + " (" + string(i) + ")";
}

myroom_first = 0;
myroom_last = i-1;
ww = -1;
hh = -1;
xx = 0;
yy = 0;