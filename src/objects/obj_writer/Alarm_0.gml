if (++strpos < string_length(text)) {
	alarm[0] = textspeed;
	if myletter == "." alarm[0] += 20;
	if myletter == "," alarm[0] += 10;
	if myletter == "!" alarm[0] += 30;
	if myletter == "?" alarm[0] += 25;
} else if (lock == 0) lock = 1;