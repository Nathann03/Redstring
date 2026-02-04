if (lock == 1) {
    lock = 0;
    pageno += 1;
    lineno = 0;
    strpos = 0;
    alarm[0] = textspeed;
    myletter = " ";
    for (var i = 1; i < string_length(global.msg[pageno])+1; i++) {
        letter[i] = string_char_at(global.msg[pageno], i)
    };
    if (letter[string_length(global.msg[pageno])] != "/") global.msg[pageno] += "/"
    text = global.msg[pageno];
}