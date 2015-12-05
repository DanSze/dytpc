module dytpc.structs;

import waved;

/**
 * A non-interleaved representation of a sound file. Each channel is in
 * it's own array of samples. 
 */
struct AudioData {
	///The channel array. Each channel is in turn an array of float samples.
	float[][] channels;
	
	///The audio sample rate.
	int sampleRate;

	/// Constructs AudioData from the wave-d Sound struct.
	this (Sound s) {
		channels = new float[][s.numChannels];
		sampleRate = s.sampleRate;
		int counter = 0;
		foreach (b ; s.data) {
			channels[counter] ~= b;
			counter = (counter + 1) % s.numChannels;
		}
	}
	
	/// Constructs a wave-d Sound struct from the AudioData.
	Sound rebuildRaws() {
		float[] newData = [];
		for (int i = 0; i < channels[0].length; i++) {
			for (int j = 0; j < channels.length; j++) {
				newData ~= channels[j][i];
			}
		}
		Sound ret;
		ret.data = newData;
		ret.sampleRate = sampleRate;
		ret.numChannels = cast(int)channels.length;
		return ret;
	}
}

/// A sound clip
struct Clip {
	/// The power of 2 length audio of the clip
	float[] origin;

	/// The list of frequencies, sorted by strength (ascending)
	int[] freqs;

	///The offset between the true and pervieved clips
	int offset;
	int length;

	///The percieved clip that should be used as a sample. Read Only.
	@property float[] clip() {
		return origin[offset .. offset + length];
	}

}

