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

	int po2Interval = minPo2(interval);
	int intervalOffset = (po2Interval - interval)/2;
	int dataOffset = cast(int)(samples.length - (samples.length / interval)*interval)/2 + interval;
	Fft fft = new Fft(po2Interval);
	Clip[] clips;
	for (int i = dataOffset - intervalOffset;
		 i < samples.length - po2Interval;
		 i += interval) {
		auto result = fft.fft(samples[i..i+po2Interval])
		              .map!(a => sqrt(a.re ^^ 2 + a.im ^^ 2)/po2Interval);
		auto indexes = new int[result.length];
		makeIndex(result, indexes);

		Clip c = Clip(samples,
					  indexes[0..10],
					  i,
					  interval);
		clips ~= c;
	}
	return clips;
}

Clip[] remix (Clip[] samples, Clip[] target) {
	foreach (i, t; target) {
		target[i] = closestMatch(samples, t);
	}
	return target;
}

private:
Clip closestMatch (Clip[] samples, Clip target) {
	Clip best = samples[0];
	foreach (a; samples[1..$]) {
		//writefln("%d < %d", mDist(a.freqs, target.freqs), mDist(best.freqs, target.freqs));
		if (mDist(a.freqs, target.freqs) < mDist(best.freqs, target.freqs))
			best = a;
	}
	return best;
}

int mDist (int[] aa, int[] bb) {
	int r = 0;
	//writefln("%d", aa.length);
	foreach (a, b; lockstep(aa, bb)) {
		//writefln("%d, %d, %d", a, b, r);
		r += abs(a - b);
	}
	return r;
}