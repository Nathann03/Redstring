error = "";
showError = false;
//the global.exf file was set in the parameters before this object was created
if (file_exists(global.exf)) {
	fileid = file_text_open_read(global.exf);
	i = 0;
	error = "";
	while (!file_text_eof(fileid)) {
		error += file_text_read_string(fileid) + chr(13) + chr(10);
		file_text_readln(fileid);
		i++;
	}
	file_text_close(fileid);
}
image_speed = 0.2;
image_xscale = 2;
image_yscale = 2;