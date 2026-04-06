draw_self();

switch (evid_id) {
		case 0: x = 0; y = 0; break;
		case 1: x = 179; y = 76; break;
		case 2: x = 179; y = 143; break;
		case 3: x = 208; y = 143; break;
		case 4: x = 208; y = 76; break;
		case 5: x = 179; y = 109; break;
		case 6: x = 179; y = 177; break;
		case 7: x = 208; y = 177; break;
		case 8: x = 208; y = 109; break;
		case 9: x = 237; y = 76; break;
		case 10: x = 237; y = 177; break;
		case 11: x = 237; y = 109; break;
}

if (array_contains(global.evid_collected, evid_id)) image_index = evid_id;