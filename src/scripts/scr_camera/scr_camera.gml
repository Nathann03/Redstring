function camerax(view = view_current) {
	return camera_get_view_x(view_camera[view]);
}
function cameray(view = view_current) {
	return camera_get_view_y(view_camera[view]);
}
function cameraw(view = view_current) {
	return camera_get_view_width(view_camera[view]);
}
function camerah(view = view_current) {
	return camera_get_view_height(view_camera[view]);
}
function camerax_set(xpos, view = view_current) {
    var _ypos = camera_get_view_y(view_camera[view]);
    camera_set_view_pos(view_camera[view], xpos, _ypos);
}
function cameray_set(ypos, view = view_current) {
    var _xpos = camera_get_view_x(view_camera[view]);
    camera_set_view_pos(view_camera[view], _xpos, ypos);
}
function cameraw_set(width, view = view_current) {
    var _height = camera_get_view_height(view_camera[view]);
    camera_set_view_size(view_camera[view], width, _height);
}
function camerah_set(height, view = view_current) {
    var _width = camera_get_view_width(view_camera[view]);
    camera_set_view_size(view_camera[view], _width, height);
}
function camera(view = view_current) {
	return {
		x: camerax(view),
		y: cameray(view),
		width: cameraw(view),
		height: camerah(view),
	};
}
function camera_set(xx, yy, ww, hh, view = view_current) {
    camera_set_view_pos(view_camera[view], xx, yy);
    camera_set_view_size(view_camera[view], ww, hh);
}