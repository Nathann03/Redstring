if bt1_pressed()
{
	//forge_stop(music)
	// forge_free(music)
	if (selected == 0) {
		room_goto_next()
	}
	if (selected == 1) {
		room_goto(room_intromenu)
	}
	if (selected == 2) {
		var list;
		list = ""
		for(var i = 0; room_exists(i); i+=1) {
			list += string(i) + ": " + room_get_name(i)
			if (scr_roomname(i) != "error") list += "(" + scr_roomname(i) + ")"
			list += "\n"
		}
		var myroom = get_integer("What room do you want to goto?#" + list, 0)
		room_goto(myroom)
	}
	if (selected == 3) {
		room_goto(testroom)
	}
	if (selected == 4) {
		var flag = get_integer("What flag do you want to set?", 0);
		var val = get_integer("What do you want to set it to?", 0);
		global.flag[flag] = val;
		show_message("global.flag[" + string(flag) + "] = " + string(val));
	}
	if (selected == 5) {
		testingInternet = true;
		request = http_get(get_string("What URL do you want to test?","https://"));
	}
}
if up_pressed()
{
	if (selected > 0) selected -= 1
}
if down_pressed()
{
	if (selected < optionno-1) selected += 1
}