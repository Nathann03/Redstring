exception_unhandled_handler(function(_ex){
	var logFile, logInfo, fileID, params, paramCount, retryCount, i;
	logInfo = "";
	logInfo += $"%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%" + "\n";
	logInfo += $"Unhandled exception!!" + "\n";
	logInfo += $"{string(_ex.longMessage)}" + "\n";
	logInfo += $"(Version {VERSION})" + "\n";
	logInfo += $"%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%" + "\n";
	
	show_debug_message(logInfo);
	
	//write the exception to a file
	retryCount = 0;
	logFile = game_save_id + "logs/crash_" + string(current_year) + "_" + string(current_month) + "_" 
		+ string(current_day) + "_" + string(current_hour) + "_" + string(current_minute) + "_" 
		+ string(current_second) + ".txt";
	if (file_exists(logFile)) { //bruh
		file_delete(logFile);
	}
	fileID = file_text_open_write(logFile);
	file_text_write_string(fileID, logInfo);
	file_text_close(fileID);
	
	//change parameters to tell the game to go to the error room
	params = "";
	paramCount = parameter_count();
	for (i = 0; i < paramCount; i++) {
		params += parameter_string(i) + " ";
		if (parameter_string(i) == "-error") {
			retryCount = real(parameter_string(i + 2));
		}
	}
	if (retryCount >= 5) {
		show_message($"A fatal error has occured, and failed to restart the game.\nPlease check the log file ({logFile}) for more information");
		game_end();
		exit;
	}
	params += $"-error {logFile} {string(retryCount)}";
	
	//restart game
	game_change(".", params);
	return 0;
});