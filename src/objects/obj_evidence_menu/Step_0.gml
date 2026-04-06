if (!instance_exists(close)) {
	for (i = 0; i < array_length(global.evid_collected); i++) {
		instance_destroy(evid_icon[i])
	}
	global.in_menu = 0;
	instance_destroy()	
}