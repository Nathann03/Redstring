var n, xx, yy;
xx = writex;
yy = writey;
for (n = 1; n <= strpos; n++)  {
	char = string_char_at(text, n);
	var char1 = string_char_at(text, n+1);
	var char2 = string_char_at(text, n+2);
	
	if (char == "#") {
		if (char1 == "c") { //color
			if (char2 == "R") color = c_red;
			if (char2 == "G") color = c_green;
			if (char2 == "B") color = c_blue;
			if (char2 == "O") color = c_orange;
			if (char2 == "Y") color = c_yellow;
			if (char2 == "W") color = c_white;
			if (char2 == "X") color = textcolor;
			n += 2;
			continue;
		}
		if (char1 == "C") { //choicer
			
		}
	}
	if (char == "%") {
		if (char1 == "%") {
			instance_destroy();
			return;
		}
	}
	
	draw_set_font(textfont);
	draw_set_color(textcolor);
	
	myletter = string_char_at(text, n);
	draw_text(xx, yy, myletter);
	xx += hspacing;
}