/*
|
| NGENDY PROGRAM
| SENIOR PROJECT
|
*/

/*
| NEEDS : T (period) , F (freq?) , N (# of breakpoints to gen)
|   Process:
          1. generate n breakpoints, but based on what ? random
             stochastic function ?
          2. generate amplitudes for those breakpoints
          3. interpolate between those breakpoints
|
*/

(
~ngendy = { | n_bpts=12, min_freq=300, max_freq=1000, samp_rate=44800|
	var bpts, amps, period, d, prev, wave, rwave, min_samp, max_samp, prim_bars, seco_bars;

	max_samp = samp_rate / min_freq;
	min_samp = samp_rate / max_freq;

	seco_bars = [min_samp, max_samp] / n_bpts;
	prim_bars = [-1 * seco_bars@@0, seco_bars@@0] / 2;

};

~wave = ~ngendy.()
)

~wave.plot;

(
a = ~wave; // 5 seconds of noise
b = Buffer.loadCollection(s, a);
)

// test it
b.get(20000,{|msg| (msg == a[20000]).postln});
// play it
x = { PlayBuf.ar(1, b, BufRateScale.kr(b), loop: 0) * 0.5 }.play;
b.free; x.free;'