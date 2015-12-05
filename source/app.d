
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
string[] sampleFile;
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
                "Multiple comma separated values are overlayed. Default: 2,4",  &intervals
        );
    } catch (Exception e) {
        result.helpWanted = true;
    } 

    if (result.helpWanted) {
        defaultGetoptPrinter("The DYTPC remix compiler generates a remix of the target file "
            ~ "from the requested samples.", result.options);
        exit(0);
    }

    if (!intervals) intervals = [2,4];

    if (!sampleFile) sampleFile = ["sample.wav"];

    AudioData target = AudioData(decodeWAV(targetFile));
    AudioData[] samples;
    foreach (f; sampleFile) {
        samples ~= [AudioData(decodeWAV(f))];
    }

    writefln("Using sample rates %s", intervals);
    writeln();

    float[][] layers;

    threadpool = taskPool();

    foreach (i, nth; intervals) {
        layers ~= [frankenmix(target, samples, nth)];
    }

    uint minl;
    try {
        minl = cast(uint)layers[0].length;
    } catch (Exception e) {
        writeln("No tracks generated!");
        exit(0);
    }

    writeln("Mastering...");
    float[] mergedTrack = (0f).repeat(minl).array;
    foreach (layer; layers) {
        auto smoothedLayer = new float[layer.length];

        foreach (i; 2 .. layer.length - 2) {
            smoothedLayer[i] = (
                1* layer[i - 2] +
                2* layer[i - 1] +
                3* layer[i    ] +
                2* layer[i + 1] +
                1* layer[i + 2]
            )/9;
        }

        mergedTrack[] += smoothedLayer[];
    }

    target.channels = [mergedTrack];
    target.rebuildRaws.encodeWAV(outputFile);
}

float[] frankenmix (AudioData music, AudioData[] samples, float fraction) {
    writeln("interval ", fraction);
    int* progressPointer = &progress;
    *progressPointer = 0;
    writeln("Analyzing...");

    Clip[] sample;
    foreach (s; samples) {
        sample ~= s.channels[0]
                  .analyze(cast(int)ceil(s.sampleRate/fraction))
                  .array;

    }

    int second = music.sampleRate;
    int interval = cast(int)ceil(cast(float)second/fraction);

    writeln("Computing Intervals...");
    float[][] intervals;
    for (int i = interval;
         i + second + interval < music.channels[0].length;
         i += second) {
        intervals ~= [music.channels[0][i - interval .. i + second + interval]];
    }


    writeln("Mixing...");
    float[] r = new float[music.channels[0].length];
    formatString = "\r%%0%dd/%%d".format(cast(int)ceil(log10(intervals.length)));
    foreach (i, interv; intervals){//threadpool.parallel(intervals)){
        (*progressPointer)++;
        writef(formatString, *progressPointer, intervals.length);
        fflush(core.stdc.stdio.stdout);
        auto target = interv.analyze(interval);
        float[] seed;
        r[interval + i*second .. interval + (i+1)*second] = seed.reduce!"a ~ b.clip"(remix(sample, target)).array[0..second];
        delete target;
    }
    writefln(formatString, *progressPointer, intervals.length);
    return r;
}