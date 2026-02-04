function scr_textrender(txr) {
	if (txr != 0) global.txr = txr;
	switch(global.txr) {
		case 4: //main overworld
			hspacing = 16;
			vspacing = 32;
			writex = x + 8;
			writey = y + 6;
			textfont = fnt_mainb;
			textcolor = c_white;
			//textsound = snd_txt1;
			textspeed = 2;
			break;
	}
}