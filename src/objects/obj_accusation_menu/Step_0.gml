if (!instance_exists(close)) {
	global.in_menu = 0;
	global.accusation_level = 0;
	instance_destroy(op1)
	instance_destroy(op2)
	instance_destroy(op3)
	instance_destroy(op4)
	instance_destroy()	
}