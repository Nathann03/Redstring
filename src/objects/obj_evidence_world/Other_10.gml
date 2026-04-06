///@description set messages to write
if (!array_contains(global.evid_collected, evid_id)) {
	evid_message = "* Discovered " + evid_name[evid_id] + ".#n* " + evid_desc[evid_id];
	array_push(global.evid_collected, evid_id);
} else {
	evid_message = "* " + evid_name[evid_id] + ". Already discovered.#n* Click the 'Evidence' button to see all discovered evidence.";
}

var truncated_strings = [""];
var temp_string = ""
var n = 0;
var last_space = -1

for (var i=1; i<=string_length(evid_message); i++) {
	if (string_char_at(evid_message, i) == "#" && string_char_at(evid_message, i+1) == "n") {
		truncated_strings[n+1] = ""
		n++;
		i+=2;
	}
	if (string_height_ext(truncated_strings[n]+string_char_at(evid_message, i), 32, 516) < 120) {
		truncated_strings[n] += string_char_at(evid_message, i);
	} else {
		last_space = string_last_pos(" ", truncated_strings[n]);
		temp_string = string_copy(truncated_strings[n], last_space+1, string_length(truncated_strings[n])-last_space+1);
		truncated_strings[n+1] = temp_string;
		truncated_strings[n] = string_delete(truncated_strings[n], last_space+1, string_length(truncated_strings[n]) - last_space+1);
		n++;
		i--;
	}
}

scr_setmsg(truncated_strings[0], "obj_evid_pickup_0");

for (var j=1; j<=n; j++) {
	scr_nextmsg(truncated_strings[j], "obj_evid_pickup_"+string([j]));
}