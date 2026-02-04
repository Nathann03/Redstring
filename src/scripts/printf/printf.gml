///@description Print a message to the IDE and Debugination consoles, with given arguments.
///@argument {String} message The message to print.
///@argument {String} [...] Any extra arguments. Keep in mind that the argument at the nth position will replace the text "{:n}".
function printf(message) {
	var argcount = argument_count;
	var offset = 1;
	var args;
	
	for (var i = 0; i < argcount; ++i) {
		args[i] = argument[i];
	}
    
	message = scr_formatstring(message, args, offset);
	
	print(message);
}