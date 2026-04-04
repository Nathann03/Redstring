if (!global.debug) { room_goto_next(); exit; }
if (room != room_title) {
	option[0] = "Start Game";
	option[1] = "File Select";
	option[2] = "Goto Room";
	option[3] = "Debug Room";
	option[4] = "Set Flag";
	option[5] = "Test Internet";
} else {
	option[0] = "Start Game";
}
optionno = array_length(option);
selected = 0;
tiler = 0;
testingInternet = false;
requestURL = "";
request = -1;

//partyindaclubtillyoucantwalknomore = forge_load("music/club.ogg")
//music = forge_loop(partyindaclubtillyoucantwalknomore, 1, 1)