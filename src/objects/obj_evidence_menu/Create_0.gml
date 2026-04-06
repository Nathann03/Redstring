close = instance_create_depth(x - 11 + sprite_get_width(spr_evidence_menu), y + 2, -11, obj_x_button)

for (i = 0; i < array_length(global.evid_collected); i++) {
	evid_icon[i] = instance_create_depth(0, 0, -11, obj_evidence_icon);
	evid_icon[i].evid_id = global.evid_collected[i];
}