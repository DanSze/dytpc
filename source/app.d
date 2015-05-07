
import std.stdio;
import std.algorithm;
import std.array;
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

    float[] mix;
    int fraction = 3;
    auto sample = voice.channels[0]
                  .analyze(voice.sampleRate/fraction)
                  .samplify
                  //.filter!"a.purity > 0.02"
                  .array;

    int interval = music.sampleRate;

    voice.channels = uninitializedArray!(float[][])(1,0);
    for (int i = interval/fraction; i + 7*interval/fraction < music.channels[0].length; i += interval) {
        writeln ("done chunk ", (i - interval/fraction)/interval);
        auto target = music.channels[0][i - interval/fraction..i + 7*interval/fraction]
                      .analyze(music.sampleRate/fraction)
                      .samplify;

        
        voice.channels[0] ~= mix.reduce!"a ~ b.clip"(remix(sample, target));
        delete target;
    }

    voice.rebuildRaws.encodeWAV("remix.wav");
}