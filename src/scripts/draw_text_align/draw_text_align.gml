/// @description  Draw text with a certain HAlign and VAlign.
/// @argument {real} x The x coordinate of the drawn string.
/// @argument {real} y The y coordinate of the drawn string.
/// @argument {string} string The string to draw.
/// @argument {constant.HAlign} [halign]=fa_center The horizantal alignment of the drawn string.
/// @argument {constant.VAlign} [valign]=fa_top The vertical alignment of the drawn string.
function draw_text_align(x, y, string, halign = fa_center, valign = fa_top) {
	var __oldHAlign = draw_get_halign();
	var __oldVAlign = draw_get_valign();
	
	draw_set_halign(halign);
	draw_set_valign(valign);
	
	draw_text(x, y, string);
	
	draw_set_halign(__oldHAlign);
	draw_set_valign(__oldVAlign);
}