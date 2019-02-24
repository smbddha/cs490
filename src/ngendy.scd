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

| IDEAS :
|  1. Granular stochastic synthesis
|    - basically granular synthesis controlled by stochastic control values
|      using the granular synthesis part as a means of interpolation between
|      the stochastically generated values
|
|  2. Stochastic synthesis ? echo ?
|    - sort of vanilla stochastic synthesis, but applied to an input waveform
|      seems like have stochastic synthesis generate an entirely novel waveform
|      can lead to very *noise-like* waves, but what if it were to stochastically
|      "decompose" an input wave that could be anything. It would select bpts for
|      the input wave and then adjust them creating a new wave in the process, but
|      would likely keep some semblance to the original wave/sound.
|
*/

(
~max_amp = 0.7;

/*
| utility function to interpolate a list of breakpoints into a wave
|
| @param pts : an array float tuples (amp, dur)
*/
~toWave = {|pts|
	var w = Array.new();
	(pts.size - 1).do({|i|
		w = w ++ [pts@@i@@0, pts@@(i+1)@@0].resize(pts@@(i+1)@@1, 'quad');
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
	n_bpts=4, // # of breakpoints
	min_freq=300, // min freq...
	max_freq=1000, // max...
	samp_rate=44800; // higher samp rate could lead to more bpts + higher freq

	var bpts, amps, period, d, prev, wave, rwave, wc1, wc2,
	min_samp, max_samp, prim_bars, seco_bars, amp_bars, mot_strms;

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
		var amp_gen, dur_gen;

		amp_gen = Pgbrown.new(~max_amp * -1, ~max_amp, step: 0.125).asStream;
		dur_gen = Pgbrown.new(seco_bars@@0, seco_bars@@1, step: 2).asStream;

		/*
		Using brownian motion random number generators

		FORMAT
		  [
		    amplitude,
		    duration,
		    amplitude walk rand # generator,
		    duration walk rand # generator
		  ]
		*/
		[
			amp_gen.next,
			dur_gen.next,
			amp_gen,
			dur_gen
		]
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
			var a,d, amp_gen, dur_gen;
			a = ad@@0; d = ad@@1; amp_gen = ad@@2; dur_gen = ad@@3;

			/*
			| TODO
			| Use specific probability distributions in the selection of
			| duration and amplitude movement
			*/

			/* The old way */
			//a = (a + rrand(amp_bars@@0, amp_bars@@1)).wrap(-1 * ~max_amp, ~max_amp);
			//d = (d + rrand(prim_bars@@0, prim_bars@@1)).wrap(seco_bars@@0, seco_bars@@1);

			/* The new way */
			[amp_gen.next, dur_gen.next, amp_gen, dur_gen]
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
h
~wave = ~ngendy.()
)

(
~granny = {
	arg in;

	/*
	| Generate the source material, for now lets use an
	| fm modulated sine wave ?
	*/

}
)

(
~gendy_echo = {
	arg in_wave; // a float array of the input waveform, should be s single cycle ?


	/* select breakpoints in the */
};
)

~pg = Pgbrown.new(lo: 0, hi: 1, step: 0.525, length: inf);
~pgs = ~pg.asStream;
~pgs.next;

~wave.plot;
~wave.size

{SinOsc.ar(440, mul: 0.2) + Line.ar(0,1,5)}.play;
s.scope

(
a = ~wave; // 5 seconds of noise
b = Buffer.loadCollection(s, a);
)

// play it
x = { PlayBuf.ar(1, b, BufRateScale.kr(b) * Line.kr(0.1, 0.7, 3), loop: 1) * 0.5 }.play;
b.free; x.free;
