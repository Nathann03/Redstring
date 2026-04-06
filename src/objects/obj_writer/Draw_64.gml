///@description draw text
var n, xx, yy;
xx = writex;
yy = writey;
color = textcolor;

var effect = array_create(4, false);

for (n = 1; n <= strpos; n++) { //is that an n++ reference?!
	char = string_char_at(text, n);
	var char1 = string_char_at(text, n+1);
	var char2 = string_char_at(text, n+2);
    
	var textx = xx;
	var texty = yy;
	
	if (char == "#") {
		if (n != 1) {
			if (string_char_at(text, n - 1) == "!") {
				n -= 1;
				continue;
			}
		}
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
		if (char1 == "X") { //effect
			//each charater moves up/down in a sine wave
			if (char2 == "W") { //wave
				effect[0] = !effect[0];
			}
			if (char2 == "S") { //shake
				effect[1] = !effect[1];
			}
			if (char2 == "G") { //god
				effect[2] = !effect[2];
			}
			if (char2 == "R") { //rainbow
				effect[3] = !effect[3];
			}
			if (char2 == "X") { //stop
				effect = array_create(array_length(effect), false);
			}
            n += 2;
			continue;
		}
		if (char1 == ">") { //buttons
			var button = char2;
			draw_sprite(scr_getbuttonsprite(scr_buttonstring_to_id(button)), 0, xx - 6, yy + 3);
            n += 2;
			continue;
		}
	}
	
	/*if (char == "\n") {
		xx = writex;
		yy += vspacing;
		continue;
	}*/
	if (char == "/") {
		lock = 1;
		continue;
	}
	if (char == "`") {
		n++;
		continue;
	}
	if (char == "%") {
		if (char1 == "%") {
			instance_destroy();
			global.npc_name = "";
			return;
		}
		lock = 1;
		event_user(0);
		continue;
	}
	
	
	draw_set_font(textfont);
	draw_set_color(color);
	draw_set_alpha(1);
    
	var finalx = textx;
	var finaly = texty;
	if (irandom(100) == 26) {
		finalx += (ranger(textshake / 2));
		finaly += (ranger(textshake / 2));
	}

	if (effect[0]) {
		finaly += (sin((global.time / 4) + (n * 1)) * 0.7);
	}

	if (effect[1]) {
		finalx += (ranger((textshake + 1) / 2));
		finaly += (ranger((textshake + 1) / 2));
	}
	//draw_text_color(finalx + 0.27, finaly + 0.27, char, bgtop, bgtop, btbtm, btbtm, 1);
	//draw_text(finalx, finaly, char);
	//xx += string_width(char);
	
	myletter = string_char_at(text, n);
	if (string_length(mystring) < n) {
		mystring += myletter;
	}
	draw_text_ext(finalx, finaly, mystring, vspacing, 516);
}