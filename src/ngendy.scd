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
~max_amp = 0.7;

~toWave = {|pts|
	var w = Array.new();
	(pts.size - 1).do({|i|
		w = w ++ [pts@@i@@0, pts@@(i+1)@@0].resize(pts@@(i+1)@@1);
	});
	w
};

/*
| TODO
| Turn into a realtime sound generator
*/
~ngendy = {
	arg
	s = 5, // # of seconds to generate
	n_bpts=5, // # of breakpoints
	min_freq=300, // min freq...
	max_freq=1000, // max...
	samp_rate=44800; // higher samp rate could lead to more bpts + higher freq

	var bpts, amps, period, d, prev, wave, rwave, wc1, wc2,
	min_samp, max_samp, prim_bars, seco_bars, amp_bars;

	max_samp = samp_rate / min_freq;
	min_samp = samp_rate / max_freq;

	seco_bars = [min_samp, max_samp] / n_bpts;
	prim_bars = [-1 * seco_bars@@0, seco_bars@@0] / 2;

	amp_bars = [-0.04,0.04];

	/*
	| NOTE
	| Have the wave be represented by an array of tuples
	| (amplitude, duration) , which will be easy to interpolate
	| together into the waveform
	*/

	wave = Array.new();

	/*
	| Generate initial points
	*/
	wc1 = 12.collect({|i|
		[rrand(~max_amp * -1, ~max_amp), rrand(seco_bars@@0, seco_bars@@1)]
	});

	wave = wave ++ ~toWave.(wc1);

	/*
	| Morph over time // perform the stochastic synthesis
	| good stuff
	*/
	while ({wave.size / samp_rate < s}, {
		/*
		| alter each of the break points
		*/

		wc2 = wc1.collect({|ad, i|
			var a,d;
			a = ad@@0; d = ad@@1;

			/*
			| TODO
			| Use specific probability distributions in the selection of
			| duration and amplitude movement
			*/
			a = (a + rrand(amp_bars@@0, amp_bars@@1)).wrap(-1 * ~max_amp, ~max_amp);
			d = (d + rrand(prim_bars@@0, prim_bars@@1)).wrap(seco_bars@@0, seco_bars@@1);
			[a,d]
		});

		/*
		| TODO
		| make it so this doesn't cause a duplication of points
		*/
		wave = wave ++ ~toWave.(wc2);
		wc1 = wc2.copy();
	});
	wave
};

~wave = ~ngendy.()
)

~wave.plot;
~wave.size

(
a = ~wave; // 5 seconds of noise
b = Buffer.loadCollection(s, a);
)

// play it
x = { PlayBuf.ar(1, b, BufRateScale.kr(b), loop: 0) * 0.5 }.play;
b.free; x.free;'