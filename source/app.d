
import std.stdio;
import waved;
import dytpc;

void main() {
    Sound input = decodeWAV("test.wav");
    AudioData s = AudioData(input);
    writefln("channels = %s", s.channels.length);
    writefln("samplerate = %s", s.sampleRate);
    writefln("samples = %s", s.channels[0].length);

    writeln(s.channels[0].analyze(48000));
}
