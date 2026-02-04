///@description
function object_get_depth(obj) {
	switch(obj) {
		case obj_writer: return -1000;
		case obj_dialoguer: return -999;
		default: return 0;
	}
}