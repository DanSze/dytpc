module dytpc.transform;


import std.numeric;
import std.algorithm;
import std.math;

import std.stdio;

import dytpc;

/// Shifts the pitch of Clip c by some amount. A positive percentage shifts up, otherwise down.
/// This method will fail if the resulting pitch is negative or larger than 1.
/// A lot of distortion is expected, this is intended.
Clip pitchShift (Clip c, float percent) {
	assert(percent > -1.0 && c.pitch * (1 + percent) < 1);

	Fft fft = new Fft (c.trueClip.length);

	auto data = fft.fft(c.trueClip);

	int rawRotate = cast(int) (c.pitch * percent * c.trueClip.length);

	if (rawRotate > 0)
		data = data[$ - rawRotate..$] ~ data[0..$ - rawRotate];
	else
		data = data[-rawRotate..$] ~ data[0..-rawRotate];
	
	float[] newSample;
	newSample = newSample.reduce!((a, b) => a ~ b.re)(fft.inverseFft(data));

	return Clip (newSample, c.offset, c.pitch + c.pitch*percent, c.purity);
}