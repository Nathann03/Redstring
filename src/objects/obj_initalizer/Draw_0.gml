if (connectedToInternet == -1) str = "Failed to connect\nto the internet.";
if (connectedToInternet == 00) str = "Connecting to the\ninternet...";
if (connectedToInternet == 01) str = "Connected!";

draw_text_center(160, 120, str);