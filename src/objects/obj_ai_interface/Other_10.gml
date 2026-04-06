///@description set messages to write
var start = string_pos(":", request_result) + 2;
var back = string_pos("clues_unlocked", request_result) - 17;
var result_message = string_copy(request_result, start, back);

var truncated_strings = ["* "];
var temp_string = ""
var n = 0;
var last_space = -1

for (var i=1; i<=string_length(result_message); i++) {
	if (string_height_ext(truncated_strings[n]+string_char_at(result_message, i), 32, 516) < 120) {
		truncated_strings[n] += string_char_at(result_message, i);
	} else {
		last_space = string_last_pos(" ", truncated_strings[n]);
		temp_string = string_copy(truncated_strings[n], last_space+1, string_length(truncated_strings[n])-last_space+1);
		truncated_strings[n+1] = temp_string;
		truncated_strings[n] = string_delete(truncated_strings[n], last_space+1, string_length(truncated_strings[n]) - last_space+1);
		n++;
		i--;
	}
}

scr_setmsg(truncated_strings[0], "obj_ai_response_0");

for (var j=1; j<=n; j++) {
	scr_nextmsg(truncated_strings[j], "obj_ai_response_0");
}