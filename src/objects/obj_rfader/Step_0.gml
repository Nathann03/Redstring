image_xscale = room_width;
image_yscale = room_height;

if (global.destination < 1) {
    printf("No destination set.\nEntrance {:1}\nRoom ", global.entrance, room_get_name(room));
    return;
}
if (!inroom) {
    if (image_alpha < 1) {
        image_alpha += fspeed;
    } else {
        inroom = true;
        room_goto(global.destination);
    }
} else {
    if (image_alpha > 0) {
        image_alpha -= fspeed;
    } else {
        instance_destroy();
    }
}
