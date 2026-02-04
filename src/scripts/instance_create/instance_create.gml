function instance_create(x, y, obj) {
	return instance_create_depth(x, y, object_get_depth(obj), obj);
}