function scr_read_secrets(){
	var file = file_text_open_read(".env");
	var content = "";

	if (file != -1) {
		while (!file_text_eof(file)) {
			content += file_text_readln(file);
		}
		file_text_close(file);
	} else {
		printf("error opening file");
	}
	
	global.secrets = content;
}