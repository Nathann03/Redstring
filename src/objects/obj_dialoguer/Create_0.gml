depth = -999;
createdWriter = false;
writer = noone;

surf = -1;
surfWidth = 600;
surfHeight = 2;
alpha = 0

spriteSpeed = 6/60;
spriteIndex = 0;

goin = false;
goout = true;

npc_name = "";
npc_profile = spr_empty;
textbox_style = spr_textbox;

if (global.npc_name != "" && global.in_menu < 2) {
	switch global.npc_name {
		case "catch_wallace": npc_name = "Catch W."; npc_profile = spr_catch_profile; break;
		case "james_okoye": npc_name = "James F."; npc_profile = spr_james_profile; break;
		case "yuki_tanaka": npc_name = "Yuki T."; npc_profile = spr_yuki_profile; break;
		case "riley_chen": npc_name = "Riley O."; npc_profile = spr_riley_profile; break;
	}
	textbox_style = spr_textbox_name;
}