if (selector_active)
{
    
    if (exiting)
    {
        image_alpha -= 0.1;
        
        if (image_alpha <= 0)
            event_user(1);
    }
    else
    {
        if (image_alpha < 1)
            image_alpha += 0.1;
        
        if (update)
        {
            ds_list_clear(suggestions);
            tmp_suggestions[0] = -4;
            num_suggestions = 0;
            positions[0] = -1;
            roomid = -1;
            
            if (dest_room != "" && dest_room == string_digits(dest_room))
                roomid = real(dest_room);
            
            for (i = real(myroom_first); i <= real(myroom_last); i++)
            {
                if (is_string(room_names[i]))
                {
                    if (case_sensitive)
                        pos = string_pos(dest_room, room_names[i]);
                    else
                        pos = string_pos(string_lower(dest_room), string_lower(room_names[i]));
                    
                    if (roomid != i && pos > 0)
                    {
                        tmp_suggestions[num_suggestions] = i;
                        positions[num_suggestions] = pos;
                        num_suggestions++;
                    }
                }
            }
            
            for (k = 0; k < num_suggestions; k++)
            {
                for (j = k; j < num_suggestions; j++)
                {
                    if (positions[k] > positions[j] || (positions[k] == positions[j] && room_names[tmp_suggestions[k]] > room_names[tmp_suggestions[j]]))
                    {
                        tmp = positions[k];
                        positions[k] = positions[j];
                        positions[j] = tmp;
                        tmp = tmp_suggestions[k];
                        tmp_suggestions[k] = tmp_suggestions[j];
                        tmp_suggestions[j] = tmp;
                    }
                }
            }
            
            if (roomid >= real(room_first) && roomid <= real(room_last))
                ds_list_add(suggestions, room_names[roomid]);
            
            for (i = 0; i < num_suggestions; i++)
                ds_list_add(suggestions, room_names[tmp_suggestions[i]]);
            
            if (update_cursor)
            {
                cursor_timer = 30;
                show_cursor = 1;
            }
            
            update_cursor = 1;
            update = 0;
        }
        
        num_suggestions = ds_list_size(suggestions);
        len = string_length(dest_room);
        dir = keyboard_check(vk_down) - keyboard_check(vk_up);
        
        if (dir != 0)
        {
            keyboard_clear(vk_down);
            keyboard_clear(vk_up);
            selection += dir;
        }
        
        if (keyboard_lastchar != "")
        {
            if (string_pos(string_lower(keyboard_lastchar), valid_chars) > 0)
            {
                dest_room += keyboard_lastchar;
                update = 1;
            }
            
            keyboard_lastchar = "";
        }
        
        if (keyboard_check(vk_backspace))
        {
            if (len > 0)
            {
                if (len == 1)
                    dest_room = "";
                else
                    dest_room = string_copy(dest_room, 1, len - 1);
                
                update = 1;
            }
            
            keyboard_clear(vk_backspace);
        }
        
        if (selection >= max_selection)
            selection = max_selection - 1;
        
        if (selection < 0)
            selection = 0;
        
        if (keyboard_check(vk_enter))
        {
            keyboard_clear(vk_enter);
            
            if (num_suggestions > 0)
            {
                name = ds_list_find_value(suggestions, selection);
                name = string_copy(name, 1, string_pos(" ", name) - 1);
                roomid = asset_get_index(name);
                
                if (room_exists(roomid))
                {
                    instance_activate_all();
                    
                    if (room == roomid)
                    {
                        selector_active = 0;
                        selector_initialized = 0;
                        sel_ever_activated = 1;
                        room_restart();
                    }
                    else
                    {
                        audio_stop_all();
                        selector_active = 0;
                        selector_initialized = 0;
                        sel_ever_activated = 1;
                        room_goto(roomid);
                    }
                }
            }
        }
        
        if (keyboard_check(vk_escape) || keyboard_check(vk_f3))
        {
            keyboard_clear(vk_escape);
            keyboard_clear(vk_f3);
            exiting = 1;
        }
        
        if (keyboard_check(vk_tab))
        {
            keyboard_clear(vk_tab);
            case_sensitive ^= 1;
            update_cursor = 0;
            update = 1;
        }
	}
}


