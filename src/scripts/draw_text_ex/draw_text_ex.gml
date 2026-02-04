///@description 
function draw_text_ex(_x, _y, _string, _hspacing, _vspacing, _shake = 0) {
	var __n;
	var __xx = _x;
	var __yy = _y;
	for (__n = 1; __n <= string_length(_string); __n++) {
		var __char = string_char_at(_string, __n);
		draw_text(__xx + (ranger(_shake/2)), __yy + (ranger(_shake/2)), __char);
		__xx += _hspacing;
	}
}