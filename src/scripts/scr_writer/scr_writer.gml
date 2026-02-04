///@description
function scr_write(messageID = 0, text = "null", textRender = -1) {
	global.mid = messageID;
	if (text != "null") global.msg[0] = text;
	if (textRender != -1) global.txr = textRender;
	
	writer = instance_create(0, 0, obj_dialoguer);
	writer.lock = 0;
	return writer;
}

function scr_instawrite(messageID = 0, text = "null", textRender = -1) {
	global.mid = messageID;
	if (text != "null") global.msg[0] = text;
	if (textRender != -1) global.txr = textRender;
	
	if (global.battle) {
	    writer = instance_create(146, 352, obj_instawriter);
	    writer.lock = 2;
	} else {
	    writer = instance_create(0, 0, obj_dialoguer);
	    writer.lock = 0;
	}
	return writer;
}

///@description Get a string of text from the lang.json file.
///@argument {String} defaultString The default English string.
///@argument {String} jsonKey The JSON key to search for. If this is blank (or not provided), it will fallback to the default string.
///@returns {String}
function scr_gettext(defaultString, jsonKey = "") {
	var file, buff, read, json, message;
	if (global.language == "en" || jsonKey == "")
		return defaultString;
	try {
		file = scr_formatstring("{:1}lang/lang_{:2}.json", [working_directory, global.language], 0);
		if (!file_exists(file)) {
			//we have to construct a fake exception struct here so it wont crash AGAIN
			throw({message: "Language file not found."});
		}
		buff = buffer_load(file);	
		read = buffer_read(buff, buffer_text);
		json = json_parse(read);
		buffer_delete(buff);
		message = json[$ jsonKey];
		if (message == "" || message == "undefined" || message = undefined) {
			message = "-unknown-string-";
		}
	} catch (_ex) {
		printf("An error occured trying to convert JSON text.");
		printf(_ex.message);
		message = "-unknown-string-";
	}
	return message;
}

///@description Localize a string.
///@argument {String} defaultString The default English string.
///@argument {String} jsonKey The JSON key to search for.
function localstring(defaultString, jsonKey) {
	return scr_gettext(defaultString, jsonKey);
}

///@description Localize a string, with given arguments.
///@argument {String} defaultString The default English string.
///@argument {String} jsonKey The JSON key to search for.
///@argument {String} [...] Any extra arguments. Keep in mind that the argument at the nth position will replace the text "{:n}".
function localstringext(defaultString, jsonKey = "") {
	var argcount = argument_count;
	var offset = 2;
	var args;
	
	for (var i = 0; i < argcount; ++i) {
		args[i] = argument[i];
	}
	
	if (global.language != "en") {
		defaultString = scr_gettext(defaultString, jsonKey);
	}
    
	defaultString = scr_formatstring(defaultString, args, offset);
	
	localstring(defaultString, jsonKey);
}

function scr_setmsg(defaultString, jsonKey = "") {
	for (var i = 0; i < 48; ++i)
		global.msg[i] = "%%";
	
	global.msgno = 0;
	global.msg[global.msgno] = scr_gettext(defaultString, jsonKey);
}

function scr_nextmsg(defaultString, jsonKey = "") {
	global.msgno++;
	global.msg[global.msgno] = scr_gettext(defaultString, jsonKey);
}

///@description Set the first message in the global.msg array, with given arguments
///@argument {String} defaultString The default English string.
///@argument {String} jsonKey The JSON key to search for.
///@argument {String} [...] Any extra arguments. Keep in mind that the argument at the nth position will replace the text "{:n}".
function scr_setmsgargs(defaultString, jsonKey) {
	var argcount = argument_count;
	var offset = 2;
	var args;
	
	for (var i = 0; i < argcount; ++i) {
		args[i] = argument[i];
	}
	
	if (global.language != "en") {
		defaultString = scr_gettext(defaultString, jsonKey);
	}
    
	defaultString = scr_formatstring(defaultString, args, offset);
	
	scr_setmsg(defaultString);
}
///@description Set the next message in the global.msg array, with given arguments
///@argument {String} defaultString The default English string.
///@argument {String} jsonKey The JSON key to search for.
///@argument {String} [...] Any extra arguments. Keep in mind that the argument at the nth position will replace the text "{:n}". Starts indexing at 1.
function scr_nextmsgargs(defaultString, jsonKey) {
	var argcount = argument_count;
	var offset = 2;
	var args;
	
	for (var i = 0; i < argcount; ++i) {
		args[i] = argument[i];
	}
	
	if (global.language != "en") {
		defaultString = scr_gettext(defaultString, jsonKey);
	}
    
	defaultString = scr_formatstring(defaultString, args, offset);
	
	scr_nextmsg(defaultString);
}

function scr_formatstring(defaultString, arguments, offset, argumentReplaceString = "{:n}") {
	var argcount = array_length(arguments);
	var currentArgument = 1;
	var length = ((argcount - offset) + 1);
	while (currentArgument < length) {
		var myarg = string_replace(argumentReplaceString, "n", string(currentArgument));
		var idx = ((currentArgument + offset) - 1);
		defaultString = string_replace(defaultString, myarg, arguments[idx]);
		currentArgument++;
	}
	return defaultString;
}

function txr_echo() {
	return (global.txr == 5);
}