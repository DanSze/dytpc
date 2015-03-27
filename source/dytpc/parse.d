module dytpc;

import waved;

struct AudioData {
	float[][] channels;
	Sound rawData;

	this (Sound s) {
		channels = new float[][s.numChannels];
		int counter = 0;
		foreach (i, b ; s.data) {
			channels[counter] ~= [b];
			counter = (counter + 1) % s.numChannels;
		}
		rawData = s;
	}
}