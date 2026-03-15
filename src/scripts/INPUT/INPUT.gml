///@description Check if a key was pressed this frame.
///@argument {Real} key The keyID to check for.
function button_pressed(key) {
    return global.inputPressed[key];
}
///@description Check if a key is currently being held.
///@argument {Real} key The keyID to check for.
function button_held(key) {
    return global.inputHeld[key];
}
///@description Check if a key was released this frame.
///@argument {Real} key The keyID to check for.
function button_released(key) {
    return !global.inputHeld[key];
}

///@description Clear a button from being pressed.
///@argument {Real} key The keyID to clear.
function button_clear(key) {
    keyboard_clear(global.inputMapKB[key]);
    global.inputPressed[key] = false;
    global.inputHeld[key] = false;
}


