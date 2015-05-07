
import std.stdio;
import std.algorithm;
import std.array;
import std.range;
import std.math;
import waved;
import dytpc;

void main() {
    AudioData music = AudioData(decodeWAV("music.wav"));
    AudioData voice = AudioData(decodeWAV("test.wav"));

    writefln("Target channels = %s", music.channels.length);
    writefln("Target samplerate = %s", music.sampleRate);
    writefln("Target frames = %s", music.channels[0].length);

    writefln("Sample channels = %s", voice.channels.length);
    writefln("Sample samplerate = %s", voice.sampleRate);
    writefln("Sample frames = %s", voice.channels[0].length);

    AudioData[3] voices;
    for (int i = 0; i < 3; i++) {
        voices[i] = voice;
        voices[i].channels = [voice.channels[0][i*$/3..(i+1)*$/3]];
    }

    float[][] layers;

    foreach (i, nth; [2,4,6]) {
        try {
            layers ~= [frankenmix(music, voice, nth)];
            } catch (Exception e){}
    }

    layers.sort!"a.length < b.length";
    int minl = layers[0].length;

    float[] mergedTrack = (0f).repeat(minl).array;
    foreach (layer; layers) {
        for (int i = 0; i < minl; i ++)
            mergedTrack[i] += layer[i]/3;
    }

    voice.channels = [mergedTrack];
    voice.rebuildRaws.encodeWAV("remix.wav");
}

float[] frankenmix (AudioData music, AudioData voice, int fraction) {
    float[] r;
    float[] seed;
    auto sample = voice.channels[0]
                  .analyze(voice.sampleRate/fraction)
                  .samplify
                  .array;

    int interval = music.sampleRate;

    voice.channels = uninitializedArray!(float[][])(1,0);
    for (int i = interval/fraction; i + (fraction + 1)*interval/fraction < music.channels[0].length; i += interval) {
        writeln (fraction, " ", i/interval);
        auto target = music.channels[0][i - interval/fraction..i + (fraction + 1)*interval/fraction]
                      .analyze(music.sampleRate/fraction)
                      .samplify;

        
        r ~= seed.reduce!"a ~ b.clip"(remix(sample, target));
        delete target;
    }
    return r;
}