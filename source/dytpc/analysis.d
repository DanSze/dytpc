module dytpc.analysis;

import std.math;
import std.numeric;
import std.algorithm;
import std.stdio;

import dytpc.structs;

/// Finds the smallest power of two above a minimum value
int minPo2 (int min) {
	return cast(int)(2 ^^ ceil(log2(min)));
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
	int dataOffset = cast(int)(remainder(samples.length, interval)/2 + interval);

	Fft fft = new Fft(po2Interval);
	Clip[] clips;

	for (int i = dataOffset - intervalOffset;
		 i < samples.length - dataOffset - intervalOffset;
		 i += interval) {
		auto result = fft.fft(samples[i..i+po2Interval])
		              .map!(a => sqrt(a.re ^^ 2 + a.im ^^ 2)/po2Interval);

		auto indexes = new int[result.length];
		topNIndex(result, indexes, SortOutput.yes);

		Clip c = Clip(i + intervalOffset,
					  interval,
					  cast(float)(indexes[$ - 1])/po2Interval,
					  result[indexes[$ - 1]]/result.sum());
		clips ~= c;
	}
	return clips;
}