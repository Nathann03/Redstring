///@desc interaction
var interactObject;
if (global.action == 0) {
    //down
    if (global.facing == 0) {
        interactObject = collision_rectangle(bbox_left, bbox_bottom, bbox_right, bbox_bottom + intextend, obj_interactable, false, true)
        if (interactObject != noone) { with interactObject scr_interact(); }
    }

    //right
    if (global.facing == 1) {
        interactObject = collision_rectangle(bbox_right, bbox_top, bbox_right + intextend, bbox_bottom, obj_interactable, false, true)
        if (interactObject != noone) { with interactObject scr_interact(); }
    }

    //up
    if (global.facing == 2) {
        interactObject = collision_rectangle(bbox_left, bbox_top - intextend, bbox_right, bbox_top, obj_interactable, false, true)
        if (interactObject != noone) { with interactObject scr_interact(); }
    }

    //left
    if (global.facing == 3) {
        interactObject = collision_rectangle(bbox_left - intextend, bbox_top, bbox_left, bbox_bottom, obj_interactable, false, true)
        if (interactObject != noone) { with interactObject scr_interact(); }
    }
}