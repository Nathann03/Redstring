///@description Set the X and Y of an object.
function setxy(x, y, target = obj_player) {
	if instance_exists(target) {
		target.x = x;
		target.y = y;
	} else
		printf("Attempting to set {:1} X/Y when no instance of the object exists.", object_get_name(target.object_index));
}