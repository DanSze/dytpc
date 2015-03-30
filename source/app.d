
import std.stdio;
import waved;
import dytpc;

void main() {
    Sound input = decodeWAV("test.wav");
    AudioData *s = new AudioData(input);
    writefln("channels = %s", s.channels.length);
    writefln("samplerate = %s", s.sampleRate);
    writefln("samples = %s", s.channels[0].length);

    output = *(s.rebuildRaws());
    output.encodeWAV("test2.wav");

}
