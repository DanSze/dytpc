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
		ret.numChannels = channels.length;
		return ret;
	}
}

/// A sound clip
struct Clip {
	/// The starting frame of the clip.
	int frame;
	/// The length of the clip, in frames.
	int length;
	/// The dominant pitch of the clip, as determined by fft. If the clip is
	/// silent, this is set to 0.
	float pitch;
	/**
	 * The purity of the dominant pitch. The purity is defined as:
	 * (magnitude of dominant pitch)/(total magnitude of pitches)
	 * As a result, this value can only range from 0.0 to 1.0.
	 * If the clip is silent, the purity is set to 0.
	 */
	 float purity;
}