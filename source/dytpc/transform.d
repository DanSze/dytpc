module dytpc.transform;


import std.numeric;
import std.algorithm;
import std.math;

import std.stdio;

import dytpc;

struct Sine {
	float freq;
	float amp;
	float phase;

	float opCall (float x) {
		return amp*sin(2*PI*freq*x + phase);
	}

	this (float f, float a, float p) {
		freq = f;
		amp = a;
		phase = p;
	}
}

/**
 * A class for resampling a Clip. Takes the true clip as input, and can output
 * an equivalent clip in any resolution.
 * 
 */
class Resampler {
	/// The component sine waves of the sample to be resampled.
	Sine[] sines;
	/// The Clip's original offsets, for resampling.
	float offset;

	/// Construct a resampler from a sample of Po2 length.
	this (Clip c) {
		offset = 2*PI*(cast(float)c.offset/c.trueClip.length);

		float[] sample = c.trueClip;
		Fft fft = new Fft (sample.length);
		auto result = fft.fft(sample);
		foreach (i, r ; result) {
			sines ~= Sine(
				cast(float)i/result.length,
				(r.re ^^ 2 + r.im ^^ 2 ) ^^ 0.5 / result.length,
				atan2(r.im, r.re)
			);
		}
	}

	/// Compute the wave's value at some point.
	float f (float x) {
		float y = 0f;
		foreach (sine; sines) {
			y += sine(x); // see opCall
		}
		return y;
	}

	/// resample the clip to the requested number of frames
	float[] resample (int frames) {
		if (frames == 1)
			return [f(PI)];

		float[] sample;
		
		for (float i = offset; i < (2*PI - offset); i += (2*PI - 2*offset)/frames) {
			sample ~= f(i);
		}

		return sample;
	}
}