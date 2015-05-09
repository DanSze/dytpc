## DYTPC

The DYTPC remix generator is pretty much what it says on the tin. This magical program wil take any two audio files and attempt to mix one to match the other.

### Features
As of the latest version, you can:
 - Mix any two audio files of any sample rate! (As long as they're .wav)
 - Construct your remix from samples of different lengths! (As long as they're 1/n)
 - Combine more than one sample length for yet more fun! (As long as you like fun)

### How to use
 1. `git clone`
 2. Build with `dub` (download  it if you need it)
 3. `dytpc -h` for options

### What's next

Currently, DYTPC uses a very simple (and low quality) pitch shifting algorithm. While some would argue that anything else would detract from the authentic flavour, I do plan to add support for different pitch shifting algorithms. Similarly, .wav isn't the most common format, so I plan to add support for other formats.

### DYTPC?
D YouTube Poop Compiler. Bad ideas are always the best.
