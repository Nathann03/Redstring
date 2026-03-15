///@description interaction
//button_clear(KEY.CONFIRM);

if (global.action > 0) return;

var object;
object[0] = collision_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom + intextend, obj_interactable, false, true); //down
object[1] = collision_rectangle(bbox_left, bbox_top, bbox_right + intextend, bbox_bottom, obj_interactable, false, true); //right
object[2] = collision_rectangle(bbox_left, bbox_top - intextend, bbox_right, bbox_bottom, obj_interactable, false, true); //up
object[3] = collision_rectangle(bbox_left - intextend, bbox_top, bbox_right, bbox_bottom, obj_interactable, false, true); //left

if (object[global.facing] != noone) {
	with (object[global.facing]) scr_interact();
}
