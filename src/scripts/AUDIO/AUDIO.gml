/// @description A simple audio wrapper for GMS2. Can load external OGG Vorbis files.
/// @description (Be sure to call free() when you are done with the track!)
/// @argument {string} filename The filename to load. Keep in mind that this loads from the same folder that the executable is in.
/// @returns {Struct.ForgeTrack} The struct that the ForgeTrack constructor constructs
function ForgeTrack(filename) constructor {
	__FORGE_SUCCESS = false;
	if (file_exists(filename)) {	
		__FORGE_OGG_FILE_NAME = filename;
		__FORGE_STREAM_ID = audio_create_stream(__FORGE_OGG_FILE_NAME);
		__FORGE_INSTANCE_ID = -1;
		__FORGE_SUCCESS = true;
	} else {
		printf("Failed to load audio track: {:1}", filename);
	}
	
	#region Play/Loop
	
	/// @description With this function you can play the loaded track.
	/// @argument {real} [volume] (Default: 1) The value to set the volume to.
	/// @argument {real} [pitch] (Default: 1) The value to set the pitch to.
	static play = function(volume = 1, pitch = 1) {
		try {
			__FORGE_INSTANCE_ID = audio_play_sound(__FORGE_STREAM_ID, AUDIO_PRIORITY.MUSIC, false, global.settings.audio.volume * volume, 0, pitch * 0.98);
			return self;
		} catch (_ex) {
			
		}
	};
	/// @description With this function you can loop the loaded track.
	/// @argument {real} [volume] (Default: 1) The value to set the volume to.
	/// @argument {real} [pitch] (Default: 1) The value to set the pitch to.
	static loop = function(volume = 1, pitch = 1) {
		try {
			__FORGE_INSTANCE_ID = audio_play_sound(__FORGE_STREAM_ID, AUDIO_PRIORITY.MUSIC, true, global.settings.audio.volume * volume, 0, pitch * 0.98);
			return self;
		} catch (_ex) {
			
		}
	};
	
	/// @description With this function you can pause the track.
	static pause = function() {
		try {
			audio_pause_sound(__FORGE_INSTANCE_ID);
			return self;
		} catch (_ex) {
			
		}
	};
	/// @description With this function you can resume the track.
	static resume = function() {
		try {
			audio_resume_sound(__FORGE_INSTANCE_ID);
			return self;
		} catch (_ex) {
			
		}
	};
	
	#endregion Play/Loop
	
	#region Set values of track
	
	/// @description With this function you can change the track volume. (Or, fade it in or out!)
	/// @argument {real} volume The value to set the volume to.
	/// @argument {real} [time] (Default: 0) How long (in milliseconds) it should take for the sound to reach the given volume. By default, this happens instantly.
	static setVolume = function(volume, time = 0) {
		try {
			audio_sound_gain(__FORGE_INSTANCE_ID, global.settings.audio.volume * volume, time);
			return self;
		} catch (_ex) {
			
		}
	};
	/// @description With this function you can change the track pitch.
	/// @argument {real} pitch The value to set the pitch to.
	static setPitch = function(pitch) {
		try {
			audio_sound_pitch(__FORGE_INSTANCE_ID, pitch * 0.98);
			return self;
		} catch (_ex) {
			
		}
	};
	/// @description This function will set the track position (in seconds).
	/// @argument {real} time The time (in seconds) to set the track position to.
	static setPosition = function(time) {
		try {
			audio_sound_set_track_position(__FORGE_INSTANCE_ID, time);
			return self;
		} catch (_ex) {
			
		}
	};
	
	#endregion Set values of track
	
	#region Get values of track
	
	/// @description With this function you can get the volume that the track is playing at.
	/// @returns {real} The volume of the track.
	static getVolume = function() {
		try {
			if (__FORGE_INSTANCE_ID != -1) {
				return audio_sound_get_gain(__FORGE_INSTANCE_ID);
			}
			printf("Attempting to check the volume of a non-playing sound.");
			return 1;
		} catch (_ex) {
			
		}
	};
	/// @description With this function you can get the pitch that the track is playing at.
	/// @returns {real} The pitch of the track.
	static getPitch = function() {
		try {
			if (__FORGE_INSTANCE_ID != -1) {
				return audio_sound_get_pitch(__FORGE_INSTANCE_ID);
			}
			printf("Attempting to check the pitch of a non-playing sound.");
			return 1;
		} catch (_ex) {
			
		}
	};
	/// @description With this function you can get the current position (in seconds) of the track.
	/// @returns {real} The current position (in seconds) of the track.
	static getPosition = function() {
		try {
			if (__FORGE_INSTANCE_ID != -1) {
				return audio_sound_get_track_position(__FORGE_INSTANCE_ID);
			}
			printf("Attempting to check the position of a non-playing sound.");
			return 1;
		} catch (_ex) {
			
		}
	};
	/// @description With this function you can get the legnth of the track.
	/// @returns {real} The volume of the track.
	static getLength = function() {
		if (!__FORGE_SUCCESS) return 0;
		try {
			if (__FORGE_INSTANCE_ID != -1) {
				return audio_sound_length(__FORGE_INSTANCE_ID);
			}
			printf("Attempting to check the length of a non-playing sound.");
			return 1;
		} catch (_ex) {
			
		}
	};
	/// @description With this function you can get the name of the OGG file that was passed in on creation.
	/// @returns {string} The name of the audio file.
	static getFileName = function() {
		try {
			return __FORGE_OGG_FILE_NAME;
		} catch (_ex) {
			
		}
	};
	/// @description With this function you can see if the track is still playing.
	/// @returns {bool} Whether or not the track is playing.
	static isPlaying = function() {
		try {
			if (__FORGE_INSTANCE_ID != -1) {
				return audio_is_playing(__FORGE_INSTANCE_ID);
			}
			printf("Attempting to check a non-playing sound.");
			return false;
		} catch (_ex) {
			
		}
	};
	
	#endregion Set values of track
	
	#region Cleanup
	
	/// @description With this function you can stop a playing track.
	static stop = function() {
		try {
			if (__FORGE_INSTANCE_ID != -1) {
				audio_stop_sound(__FORGE_INSTANCE_ID);
				return self;
			}
			printf("Attempting to stop a sound that was never started.");
			return self;
		} catch (_ex) {
			
		}
	};
	/// @description With this function you can free the track (and the stream) from memory. ALWAYS call this when you are done using a track in game!
	static free = function() {
		try {
			if (isPlaying()) stop();
			audio_destroy_stream(__FORGE_STREAM_ID);
		} catch (_ex) {
			
		}
	};
	
	#endregion Cleanup
};