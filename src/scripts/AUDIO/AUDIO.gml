/*
	ForgeOGG is a custom audio wrapper that i made for ChronoGenic.
	It isn't revolutionary by any standards, but it's nice because it does most of the boring stuff for you
*/
#region Forge OGG
function forge_load(filename) {
	try {
		return audio_create_stream(filename);
	} catch (_ex) {
		printf($"Failed to create audio stream from file {filename}");
		printf(_ex.longMessage);
	}
}
function forge_play(index, volume, pitch) {
	try {
		return audio_play_sound(index, 0, false, volume * global.settings.audio.volume, 0, pitch);
	} catch (_ex) {
		printf("Failed to play song.");
		printf(_ex.longMessage);
	}
}
function forge_loop(index, volume, pitch) {
	try {
		return audio_play_sound(index, 0, true, volume * global.settings.audio.volume, 0, pitch);
	} catch (_ex) {
		printf("Failed to loop song.");
		printf(_ex.longMessage);
	}
}
function forge_pause(index) {
	try {
		audio_pause_sound(index);
	} catch (_ex) {
		printf("Failed to pause song.");
		printf(_ex.longMessage);
	}
}
function forge_resume(index) {
	try {
		audio_resume_sound(index);
	} catch (_ex) {
		printf("Failed to resume song.");
		printf(_ex.longMessage);
	}
}
function forge_stop(index) {
	try {
		if (index == all) {
			audio_stop_all();
			return 0;
		}
		audio_stop_sound(index);
	} catch (_ex) {
		printf("Failed to stop song.");
		printf(_ex.longMessage);
	}
}
function forge_free(index) {
	try {
		//return audio_destroy_stream(index);
	} catch (_ex) {
		printf("Failed to free song.");
		printf(_ex.longMessage);
	}
}
function forge_get_length(index) {
	try {
		return audio_sound_length(index);
	} catch (_ex) {
		printf("Failed to fetch the song length.");
		printf(_ex.longMessage);
		return 0.01;
	}
}
function forge_is_playing(index) {
	try {
		return audio_is_playing(index);
	} catch (_ex) {
		printf("Failed to check if audio is playing.");
		printf(_ex.longMessage);
		return false;
	}
}
function forge_get_pos(index) {
	try {
		return audio_sound_get_track_position(index);
	} catch (_ex) {
		printf("Failed to get audio position.");
		printf(_ex.longMessage);
		return 0;
	}
}
function forge_set_pos(index, time) {
	try {
		return audio_sound_set_track_position(index, time);
	} catch (_ex) {
		printf("Failed to set audio position.");
		printf(_ex.longMessage);
		return false;
	}
}
function forge_get_volume(index) {
	try {
		return audio_sound_get_gain(index);
	} catch (_ex) {
		printf("Failed to get audio volume.");
		printf(_ex.longMessage);
		return 0;
	}
}
function forge_set_volume(index, level, time = 0) {
	try {
		return audio_sound_gain(index, level, time);
	} catch (_ex) {
		printf("Failed to set audio volume.");
		printf(_ex.longMessage);
		return false;
	}
}
#endregion Forge OGG

#region Compatibility
function sound_play(index, priority = AUDIO_PRIORITY.SFX) {
	return audio_play_sound(index, priority, false, global.settings.audio.volumeSFX);
}
function sound_stop(index) {
	audio_stop_sound(index);
}
#endregion Compatibility