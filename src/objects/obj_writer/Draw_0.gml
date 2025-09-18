var n, xx, yy, myletter;
xx = writex;
yy = writey;
for (n = 1; n < pos+1; n++)
{
	draw_set_font(textfont);
	draw_set_color(textcolor);
	
	myletter = string_char_at(text,n);
	draw_text(xx, yy, myletter);
	xx += hspacing;
}