#region Input
for (var i = 0; i < KEY.COUNT; ++i) {
	global.inputPressedKB[i] = keyboard_check_pressed(global.inputMapKB[| i]);
	global.inputHeldKB[i] = keyboard_check(global.inputMapKB[| i]);
}
#endregion Input