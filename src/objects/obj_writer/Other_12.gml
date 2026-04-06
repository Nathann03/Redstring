///@description format text
formatted = true;

var star = false;
var _char = " ";
charline = 0;

var _debugprint = false;

var _maxchar = maxchar;
maxchardebug = _maxchar;

for (var i = 1; i <= length; i++) {
	_char = string_char_at(text, i);
	if (_char == "#") {
		if (string_char_at(text, i + 1) == ">") {
			var _bt = string_char_at(text, i + 2);
			if (gamepad == false) {
				text = string_delete(text, i, 3);
				if (_bt == "Z") text = string_insert("[Z]", text, i);
				if (_bt == "X") text = string_insert("[X]", text, i);
				if (_bt == "C") text = string_insert("[C]", text, i);
				if (_bt == "U") text = string_insert("[UP]", text, i);
				if (_bt == "D") text = string_insert("[DOWN]", text, i);
				if (_bt == "L") text = string_insert("[LEFT]", text, i);
				if (_bt == "R") text = string_insert("[RIGHT]", text, i);
				i += 3;
			} else {
				text = string_insert(" ", text, i - 1);
				text = string_insert(" ", text, i + 4);
				i += 3;
			}
		}
	}
}

length = strlen(text);

lastspace = -1;
originaltext = text;

for (var i = 1; i <= length; i++) {
	_char = string_char_at(text, i);
	if (_debugprint) printf("Checking character \"{:1}\" ({:2})", _char, charline);
	//manual newline
	if (_char == "\n") {
		lastspace = -1;
		charline = 0;
	}
	
	if (_char == "#") {
		//the amount of characters after the # can be different, but this is a rough estination
		charline -= 2;
		continue;
	}
	if (_char == "`") {
		charline -= 2;
		continue;
	}
	
	if (charline >= _maxchar && _char != " ") {
		if (_debugprint) printf("Charline ({:1}) has exceeded limit (char: {:2}). Breaking..", charline, _char);
		if (lastspace != -1) {                    
			text = string_delete(text, lastspace, 1);
			text = string_insert($"\n{star ? "  " : ""}", text, lastspace);
			length++;
			if (star) length += 2;
			i = lastspace + (star ? 2 : 1);
			lastspace = -1;
		} else {
			text = string_insert("\n", text, i);
			i++;
			length++;
			if (star) length += 2;	
		}
		charline = ((star) ? 3 : 0) + 1;
		continue;
	}
	
	if (_char == "*") star = true;
	if (_char == " ") lastspace = i;
	
		
	charline++;
}

alarm[0] = textspeed;
