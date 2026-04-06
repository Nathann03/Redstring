if (global.action == 0) {
	global.action = 2;
	global.destination = destRoom;
	fader = instance_create(0, 0, obj_rfader);
}

//instance_create_layer(x_offset, y_offset, "Instances", obj_player); // not working
// obj_player.x = x_offset;
// obj_player.y = y_offset;