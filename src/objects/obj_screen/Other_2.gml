screen = surface_create(screenW, screenH);
//if the gpu doesn't support surfaces, revert back to viewports
if (screen == -1) { instance_destroy(); exit; }