
import std.stdio;
import std.algorithm;
import std.array;
import std.math;
import waved;
import dytpc;

void main() {
    Sound input = decodeWAV("test.wav");
    AudioData s = AudioData(input);
    writefln("channels = %s", s.channels.length);
    writefln("samplerate = %s", s.sampleRate);
    writefln("samples = %s", s.channels[0].length);

    auto results = s.channels[0].analyze(6000);
    float[] pureSound = [];

    foreach (i, result; results) {
    	if (result.purity > 0.01){
            auto r = new Resampler(result);
            auto newSample = r.resample(6000);
    		pureSound ~= newSample;
    		writefln("%s | %s | %s", result.pitch, result.purity, avgDiff(result.clip, newSample));
    	}
    }
    s.channels = [pureSound];
    s.rebuildRaws().encodeWAV("test2.wav");
}

float avgDiff (float[] a, float[] b) {
    float r = 0f;
    for (int i = 0; i < a.length; i++) {
        r += a[i] - b[i];
    }
    return r/a.length;
}