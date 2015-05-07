module dytpc.analysis;

import std.math;
import std.numeric;
import std.algorithm;
import std.array;
import std.exception;

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

		Clip c = Clip(samples[i .. i + po2Interval],
					  intervalOffset,
					  cast(float)(indexes[$ - 1])/po2Interval,
					  result[indexes[$ - 1]]/result.sum());
		clips ~= c;
	}
	return clips;
}

/// Constructs a set of Samples from a set of equal length clips.
Sample[] samplify (Clip[] clips) {
	Fft fft = new Fft(clips[0].trueClip.length);
	Sample[] samples;

	foreach (c; clips) 
		samples ~= samplify(c, fft);
	return samples;
}

Sample samplify (Clip clip, Fft fft) {
	auto data = fft.fft(clip.trueClip).map!(a => a.re ^^ 2 + a.im ^^ 2);
	int[] indexes = new int[50];
	topNIndex(data, indexes, SortOutput.no);
	sort(indexes);
	return Sample (clip,
	               cast(double)(clip.trueClip.length)/indexes[$-1],
	               (clip.pitch*clip.trueClip.length - indexes[0])/clip.pitch*clip.trueClip.length,
	               [indexes[0], indexes[$-1]]);
}

Sample samplify (Clip clip) {
	return samplify(clip, new Fft(clip.trueClip.length));
}

Sample[] remix (Sample[] samples, Sample[] target) {
	foreach (i, t; target) {
		target[i] = closestMatch(samples, t);
	}
	return target;
}

private:
Sample closestMatch (Sample[] samples, Sample target) {
	auto validSamples = samples.filter!(a => a.canBecome(target)).array;

	enforce(validSamples.length > 0, "No valid samples found!");

	validSamples.sort!((a, b) => (a.pitch - target.pitch) ^^ 2 < (b.pitch - target.pitch) ^^ 2);

	return pitchShift(validSamples[0], target.pitch/validSamples[0].pitch - 1);
}

bool canBecome (Sample from, Sample into) {
	return from.pitch*from.up > into.pitch && from.pitch*from.down < into.pitch;
}