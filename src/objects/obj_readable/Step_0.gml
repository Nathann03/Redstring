if (interact = 1) {
    event_user(0);
}
if (interact = 2 and !instance_exists(dialoguer)) {
    interact = 3;
    alarm[0] = 3;
}