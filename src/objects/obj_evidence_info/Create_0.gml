close = instance_create_depth(x - 11 + sprite_get_width(spr_evidence_info_big), y + 2, -12, obj_x_button_submenu)

//evid_icon = instance_create_depth(38, 74, -12, obj_evidence_icon);
evid_id = global.evid_clicked;


evid_name = ["Null", "Tool Pegboard", "Wrench on Ground", "Morgan's Body", "Fishing Wire", "Letter Opener", "Chemical Vial", "Research Station Log", "Muddy Boot Prints and Wet Rope", "Timed Chemical Test", "Beacon Room Security Log", "Yuki's Damp Jacket"];
evid_desc = [
	"This piece of evidence doesn't exist. If you're seeing this, it means I messed up somewhere.",
	"The tool pegboard is meticulously organized with labeled hooks. One hook labeled 'WRENCH - 14' is empty. No dust outline, so it was removed recently.",
	"A 14-inch wrench lies on the concrete floor near Morgan's body. It's wet and appears to have been rinsed clean.",
	"Morgan's body lies near the edge of the tidal pool. There's blunt force trauma to the back of his head, seeping blood. His skin is pruned from prolonged exposure to the humid, misty environment, suggesting he's been here for many hours.",
	"A coil of thin, ultra-strong fishing wire sits on a shelf. The wire is taut and sharp enough to cut skin if pulled tight.",
	"A sharp letter opener sits on the desk. The blade is long and pointed, with a weighted brass handle.",
	"A research chemical vial sits on the work bench, half empty. The label warns: 'TOXIC - Fatal if ingested in high concentrations.'",
	"The research station log shows Morgan's last entry, timestamped yesterday at 9:45 PM: 'Heading down to tidal pool lab at 10:00 PM for late night contamination sampling. Need to collect data during high tide.'",
	"Large boot prints track across the floor, the mixture of wet mud and coarse sand thick and caked on. Next to them sits a coil of heavy marine rope, soaking wet and covered in fresh seaweed. The rope has abrasion marks, like it was used to secure something heavy during rough conditions.",
	"A row of test tubes sits in a rack, each labeled with times: '9:00 PM', '9:30 PM', '10:00 PM', '10:30 PM', '11:00 PM', '11:30 PM', '12:00AM'. Each tube contains a water sample at different stages of a color-changing chemical reaction.",
	"A security tablet by the door shows access logs: 'BEACON ROOM - Entered 7:09 PM: R. Okoye (Keycard #004). Entered 12:14 AM: J. Finnegan (Keycard #002). Exited 3:07 AM: J. Finnegan (Keycard #002). Exited 7:51 AM: R. Okoye (Keycard #004).'",
	"A professional jacket is draped over a chair. The fabric on the sleeves and lower hem is noticeably damp, not just humid but actually wet. The dampness has a faint chemical smell."
];