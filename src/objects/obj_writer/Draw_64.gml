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
		/*if (char1 == "n") { //newline
			yy += vspacing;
			xx = writex;
			n += 1;
			continue;
		}*/
	}
	if (char == "%") {
		if (char1 == "%") {
			instance_destroy();
			global.npc_name = "";
			return;
		}
	}
	/*if (n > 1 && (n-1) % 32 == 0) { //automatic text wrapping (monospaced only)
		yy += vspacing;
		xx = writex;
		if (char == " ") n += 1;
	}*/
	/*if (xx >= 590) { // automatic text wrapping (bad)
		yy += vspacing;
		xx = writex;
		if (char == " ") n += 1;
	}*/
	//string_width_ext(text,vspacing,516)
	
	draw_set_font(textfont);
	draw_set_color(textcolor);
	
	myletter = string_char_at(text, n);
	//draw_text(xx, yy, myletter);
	//xx += string_width(myletter);
	
	if (myletter == "\\") {
		//don't
	} else if (string_length(mystring) < n) {
		mystring += myletter;
	}
	
	draw_text_ext(xx, yy, mystring, vspacing, 516);
}