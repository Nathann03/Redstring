winwin_update();

//debug cmds
if (keyboard_check_pressed(192)) { //tilde
	if (!consoleActive) {
		consoleActive = true;
		input = "";
		printf("Redstring {:1}", VERSION);
		printf("WARNING: console is enabled, all game input will be ignored!");
		show_debug_message("Console activated!");
	} else {
		consoleActive = false;
	}
}

var _debugWindowFocused = winwin_has_focus(extra);
var typed = keyboard_string;
//var typed = ((_debugWindowFocused) ? winwin_keyboard_get_string(extra) : keyboard_string);
if (typed != "" && canInput && consoleActive) {
	typed = string_replace_all(typed, "`", "");
	input += typed;
	keyboard_string = "";
	alarm[0] = 30;
}

if (consoleActive) {
	if (keyboard_check_pressed(vk_backspace) && input != "") {
		input = string_delete(input, string_length(input), 1);
	}
	
	if (keyboard_check_pressed(vk_enter) && input != "") {
		var _parts = string_split(input, " ");
		var arg = _parts;
		var _command = string_lower(_parts[0]);
		var _len = array_length(_parts)-1; //subtract 1 to exclude the command
		printf("> {:1}", input);
		input = "";
		
		if (_command == "help") {
			var _helpCommand;
			if (array_length(_parts) > 1) _helpCommand = string_lower(_parts[1]);
			else _helpCommand = "";
			if (_helpCommand == "") {
				print("COMMANDS");
				print("QUIT: quit the game");
				print("RESET: restart the game");
				print("CREDITS: view who made the game");
				print("PING: ping a website to test internet connection");
				print("GLOBAL: Set a global value");
				print("CLS: clear the console");
			} else if (_helpCommand == "quit") {
				print("QUIT: quit the game using gamemaker's built-in game_end() function.");
				print("ARGUMENTS: <  >");
			} else if (_helpCommand == "reset") {
				print("RESET: restart the game using gamemaker's built-in game_restart() function.");
				print("ARGUMENTS: <  >");
			} else if (_helpCommand == "credits") {
				print("CREDITS: lists everybody who worked on this game!");
				print("ARGUMENTS: <  >");
			} else if (_helpCommand == "ping") {
				print("PING: ping a certain website to test internet connection.");
				print("ARGUMENTS: < websiteURL >");
			} else if (_helpCommand == "cls") {
				print("CLS: simply clears the console window.");
				print("ARGUMENTS: <  >");
			}
		} else if (_command == "quit") {
			game_end();
		} else if (_command == "reset") {
			game_restart();
		} else if (_command == "ping") {
			httpReqURL = _parts[1];
			if (!string_starts_with(httpReqURL, "https://")) {
				if (string_starts_with(httpReqURL, "https://")) {
					printf("Please use HTTPS!");
					return;
				}
				httpReqURL = "https://" + httpReqURL;
			}
			httpRequest = http_get(httpReqURL);
			httpReqStartTime = current_time; //calculate in milliseconds
			testingInternet = true;
			canInput = false;
		} else if (_command == "credits") {
			print("-- REDSTRING --");
			print("Backend, Project Manager              Nathan Nguyen");
			print("Narrative / AI Interaction Lead       Faith Rider");
			print("Game Programming, Frontend Lead       Elias Weitfle");
			print("Extra Frontend Programming            Noah Rider");
			print("2025/2026 Capstone Project");
			print("Thanks for playing!");
		} else if (_command == "global") {
			if (_len > 2) {
				print("Usage: global varname value");
				return;
			}
			if (!variable_global_exists(arg[1])) {
				printf("Global variable \"{:1}\" not found.", string_upper(arg[1]));
				return;
			}
			variable_global_set(arg[1], arg[2]);
			printf("global.{:1} = {:2}", arg[1], arg[2]);
		} else if (_command == "cls") {
			d_Message = [];
		} else {
			printf("unknown command: {:1}", string_upper(_command));
		}
	}
} else input = "";