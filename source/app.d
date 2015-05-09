
import std.stdio;
import std.algorithm;
import std.array;
import std.range;
import std.math;
import std.string;
import std.parallelism;
import std.getopt;
import std.c.stdlib;

import waved;
import dytpc;

//Thread sync stuff
TaskPool threadpool;
int progress;
string formatString;

//getopt stuff
int[] intervals;
string targetFile = "target.wav";
string sampleFile = "sample.wav";
string outputFile = "out.wav";


void main(string[] args) {

    arraySep = ",";

    GetoptResult result;
    try {
        result = getopt(args,
            "output|o",
                "The output file. Default: out.wav",  &sampleFile,
            "sample|s",
                "The wav file containing sample audip. Default: sample.wav",  &sampleFile,
            "target|t",
                "The wav file containing target audio. Default: target.wav",  &targetFile,
            "intervals|i",
                "The fraction of a second at which to analyse the audio. "~
                "Multiple comma separated values are overlayed. Default: 2,4,8",  &intervals
        );
    } catch (Exception e) {
        result.helpWanted = true;
    } 

    if (result.helpWanted) {
        defaultGetoptPrinter("The DYTPC remix compiler generates a remix of the target file "
            ~ "from the requested samples.", result.options);
        exit(0);
    }

    if (!intervals) intervals = [2,4,8];

    AudioData target = AudioData(decodeWAV(targetFile));
    AudioData sample = AudioData(decodeWAV(sampleFile));

    writefln("Combining %s and %s into %s", targetFile, sampleFile, outputFile);
    writefln("Using sample rates %s", intervals);
    writeln();

    writefln("Target channels = %s", target.channels.length);
    writefln("Target samplerate = %s", target.sampleRate);
    writefln("Target frames = %s", target.channels[0].length);
    writeln();

    writefln("Sample channels = %s", sample.channels.length);
    writefln("Sample samplerate = %s", sample.sampleRate);
    writefln("Sample frames = %s", sample.channels[0].length);
    writeln();

    AudioData[3] voices;
    for (int i = 0; i < 3; i++) {
        voices[i] = sample;
        voices[i].channels = [sample.channels[0][i*$/3..(i+1)*$/3]];
    }

    float[][] layers;

    threadpool = taskPool();

    foreach (i, nth; intervals) {
        try {
            layers ~= [frankenmix(target, sample, nth)];
        } catch (Exception e){
            writefln("\nCouldn't generate the 1/%s interval track; dropping.", nth);
        }
    }

    int minl;
    try {
        minl = layers[0].length;
    } catch (Exception e) {
        writeln("No tracks generated!");
        exit(0);
    }

    float[] mergedTrack = (0f).repeat(minl).array;
    foreach (layer; layers) {
        mergedTrack[] += layer[];
    }

    sample.channels = [mergedTrack];
    sample.rebuildRaws.encodeWAV(outputFile);
}

float[] frankenmix (AudioData music, AudioData voice, int fraction) {
    writeln("interval ", fraction);
    int* progressPointer = &progress;
    *progressPointer = 0;

    auto sample = voice.channels[0]
                  .analyze(cast(int)ceil(cast(float)voice.sampleRate/fraction))
                  .samplify
                  .array;

    int second = music.sampleRate;
    int interval = cast(int)ceil(cast(float)second/fraction);
    float[] seed;

    float[][] intervals;
    for (int i = interval;
         i + second + interval < music.channels[0].length;
         i += second) {
        intervals ~= [music.channels[0][i - interval .. i + second + interval]];
    }

    float[] r = new float[music.channels[0].length];
    formatString = "\r%%0%dd/%%d".format(cast(int)ceil(log10(intervals.length)));
    foreach (i, interv; threadpool.parallel(intervals)){
        (*progressPointer)++;
        writef(formatString, *progressPointer, intervals.length);
        fflush(core.stdc.stdio.stdout);
        auto target = interv.analyze(interval)
                      .samplify;
        r[interval + i*second .. interval + (i+1)*second] = seed.reduce!"a ~ b.clip"(remix(sample, target))[0..second];
        delete target;
    }
    writefln(formatString, *progressPointer, intervals.length);
    return r;
}