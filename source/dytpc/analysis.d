module dytpc.analysis;

import std.math;
import std.numeric;
import std.algorithm;
import std.array;
import std.exception;
import std.range;

import std.stdio;

import dytpc;

/// Finds the smallest power of two above a minimum value
int minPo2 (int min) {
	return cast(int)(2 ^^ ceil(log2(min)));
}

/// Finds the largest power of two below a maximum value
int maxPo2 (int min) {
	return cast(int)(2 ^^ floor(log2(min)));
}

enum nDims = 200;

/**
 * Analyses a channel, generating clip informaton for each interval.
 *
 * The actual interval analyzed for each clip will be up to two times larger, and
 * will always be a power of two. Because of this, the first and last intervals
 * of the audio will be omitted from the analysis. There will also be overlap
 * between the data analyzed. Only a multiple of interval will be analyzed.
 *
 * Params:
 * 	samples =		The sampled audio to be analysed
 *	interval = 		The desired Clip length
 * 
 * Returns:
 *	An array of Clips, each of length interval.
 *
 */
Clip[] analyze (float[] samples, int interval) {

	static int dataOffset = -1;
	int po2Interval = minPo2(interval);
	int intervalOffset = (po2Interval - interval)/2;
	if (dataOffset == -1) {
		dataOffset = cast(int)(samples.length - (samples.length / interval)*interval)/2 + interval;
	}
	Fft fft = new Fft(po2Interval);
	Clip[] clips;
	for (int i = dataOffset - intervalOffset;
		 i < samples.length - po2Interval;
		 i += interval) {
		auto result = fft.fft(samples[i..i+po2Interval])
		             .map!(a => sqrt(a.re ^^ 2 + a.im ^^ 2)/po2Interval);
		auto indexes = new int[result.length];
		makeIndex(result, indexes);
		reverse(indexes);
		Clip c = Clip(samples,
					  cast(float[])indexes[0 .. nDims],
					  i,
					  interval);
		clips ~= c;
	}
	return clips;
}

Clip remix (Clip[] samples, Clip target, Clip previous, float interval) {
	Clip best = samples[0];
	float[] freqs = target.freqs;
	if (previous.freqs){
		freqs[] *= interval;
		freqs[] += previous.freqs[];
		freqs[] /= interval + 1;
	}
	foreach (a; samples[1..$]) {
		if (mDist(a.freqs, target.freqs) < mDist(best.freqs, target.freqs))
			best = a;
	}
	return best;
}

float mDist (float[] aa, float[] bb) {
	float r = 0;
	float factor = nDims;
	foreach (a, b; lockstep(aa, bb)) {
		r += factor*abs(a - b);
		factor /= 1.5;
	}
	return r;
}