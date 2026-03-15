var str;
if (connectedToInternet == -1) str = "Failed to connect\nto the server.";
if (connectedToInternet == 00) str = "Connecting to the\nserver...";
if (connectedToInternet == 01) str = "Connected!";

draw_text_align(160, 120, str);