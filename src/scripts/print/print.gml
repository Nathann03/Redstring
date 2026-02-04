///@param message The message to print
///@param [important] If true, a pop-up will show the message as well
function print(message, important = false) {
	if (global.debug == true) {
		var fromText = "";
		try {if (object_index != obj_debugination) fromText = object_get_name(object_index) + ": ";}
		catch(e) {fromText = "";}
		var finalMsg = string(fromText + string(message));
		show_debug_message(finalMsg);
		if (important) show_message(finalMsg);
			
		if (!instance_exists(obj_debugination)) return;
		with (obj_debugination) {
			array_push(d_Message, finalMsg);
			if (array_length(d_Message) > maxmsg) {
				array_delete(d_Message, 0, 1);
			}
		}
	}
}