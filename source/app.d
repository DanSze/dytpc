
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
    		pureSound ~= result.clip;
    		writefln("%s | %s", result.pitch, result.purity);
    	}
    }
    foreach(i; 0 .. 5)
    {
    	pureSound ~= pureSound;
    }
    s.channels = [pureSound];
    s.rebuildRaws().encodeWAV("test2.wav");
}
