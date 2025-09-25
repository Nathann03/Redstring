//set target to the screen surface
if (!surface_exists(screen)) screen = surface_create(screenW, screenH);
if (draw_screen()) surface_set_target(screen);


//check inputs, and map it to their global variables
for (var i = 0; i < 24; i+=1)
    global.inputHeld[i] = keyboard_check(global.buttonMapKeyboard[i]);
global.inputHeld[9] |= keyboard_check(vk_enter);
global.inputHeld[10] |= keyboard_check(vk_shift);
global.inputHeld[11] |= keyboard_check(vk_control);
for (var i = 0; i < 24; i+=1)
    global.inputPressed[i] = keyboard_check_pressed(global.buttonMapKeyboard[i]);
global.inputPressed[9] |= keyboard_check_pressed(vk_enter);
global.inputPressed[10] |= keyboard_check_pressed(vk_shift);
global.inputPressed[11] |= keyboard_check_pressed(vk_control);