draw_self();
draw_sprite(spr_evidence, global.evid_clicked, 28, 44)

draw_set_font(fnt_main)

draw_text(x+60,y+18,evid_name[global.evid_clicked]);
draw_text_ext(x+20,y+50,evid_desc[global.evid_clicked], 14, 260);