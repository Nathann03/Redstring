if (!global.debug) { room_goto_next(); exit; }
option[0] = "Start Game";
option[1] = "File Select";
option[2] = "Goto Room";
option[3] = "Debug Room";
option[4] = "Set Flag";
option[5] = "Test Internet";
optionno = array_length(option);
selected = 0;
tiler = 0;
testingInternet = false;
request = -1;

//partyindaclubtillyoucantwalknomore = forge_load("music/club.ogg")
//music = forge_loop(partyindaclubtillyoucantwalknomore, 1, 1)