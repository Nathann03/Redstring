if (global.ai_mode == 1 && global.player_msg != "" && request_sent == 0) {
	request_sent = 1;
	
	var request_header = ds_map_create();
	ds_map_add(request_header, "Authorization", "Bearer " + global.secrets);
	ds_map_add(request_header, "Content-Type", "application/json");
	
	npc_id = global.npc_name
	player_question = global.player_msg;
	
	for (i = 0; i < array_length(global.evid_collected); i++) {
		if (global.evid_collected[i] > 9) {
			found_clues[i] = "EVID_" + string(global.evid_collected[i]);
		} else {
			found_clues[i] = "EVID_0" + string(global.evid_collected[i]);
		}
	}

	request_data = 
	{
		"npc_id": npc_id,
		"player_question": player_question,
		"generation_backend": "auto",
		"game_state": {
			"found_clues": found_clues,
			"asked_questions": asked_questions,
			"npc_id": npc_id
		}
	};
	
	request = http_request("http://3.16.160.186:8000/dialogue", "POST", request_header, json_stringify(request_data));
	show_debug_message("request_data " + json_stringify(request_data));
	
	ds_map_destroy(request_header);
	global.player_msg = ""
}

if (global.ai_mode == 1 && request_result != "" && request_sent == 1) {
	request_sent = 0;
	
	show_debug_message("response_data " + request_result);
	interact = 1;
	event_user(0); //children of this object can put their text here
	global.txr = 4;
	writer = instance_create_depth(0, 0, object_get_depth(obj_dialoguer), obj_dialoguer);
	global.action = 1;
	interact = 2;
	
	request_result = "";
}

if (interact == 2 && !instance_exists(writer)) {
	interact = 3;
	alarm[3] = 3; //buffer a little time until resetting interact
}