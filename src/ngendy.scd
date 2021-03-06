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
w = Window("My Analyzer", Rect(0, 0, 511, 300));
f = FreqScopeView(w, w.view.bounds);
w.onClose_({ f.kill }); // YOU MUST HAVE THIS
w.front;
)

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
	s = 10, // # of seconds to generate
	n_bpts=6, // # of breakpoints
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
	wc1 = n_bpts.collect({|i|
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

~wave = ~ngendy.()
)



(
/* ------------------------------------------------------------------
 * |
 * | IMPLEMENTATION W/ GRANULAR FEATURE
 * |
 * -----------------------------------------------------------------*/
~interpolate = {
	arg type=\lin, amps, durs, min_freq=30, max_freq=1000, samp_rate = 48000;

	var index, phase, out, amp, amp_next, speed, n_bpts, amp_out, rate;

	out = Array.new();

	n_bpts = amps.size;
	index=0; phase = 1.0;
	amp = 0.0; amp_next = 0.0;
	while ({ index < amps.size }, {
		if (phase >= 1.0, {
			phase = phase - 1.0;

			// get the next amplitude
			amp = amp_next;
			index = index+1;

			if (index < amps.size, {
				amp_next = amps[index];
				rate = durs[index];
			}, {
				amp_next = 0.0;
				rate = 1.0;
			});

			speed = max_freq - min_freq * rate + min_freq * (1 / samp_rate) * n_bpts;
		});

		switch (type,
			\lin, {
				// simple linear interpolation
				amp_out = (1.0 - phase * amp) + (phase * amp_next);
			},
			\gran, {
				// granular interpolation (also linear too)
				/*
				var a,an;
				[i_env, i_env_next, env[i_env], env_next[i_env_next]].postln;
				a = amp * env[i_env] * samp[off];
				an = amp_next * env_next[i_env_next] * samp[off_next];
				amp_out = (1.0 - phase * a) + (phase * an)
				*/
			},
			{}
		);
		phase = phase + speed;
		out = out.add(amp_out);
		out.postln;
	});
	out
};

~freq_mul = 1.0;
~max_amp = 0.7;

~samp = Wavetable.sineFill(1024, [1,0.5,0.25,0.5],[0,0,0.2,0.5]);
~amp_rand = 0.05;

~ngendy2 = {
	arg n_bpts, interpolate=\lin, min_freq=30, max_freq=1000, samp_rate = 48000,
	f; // for testing shit

	/*
	| Create sonic material for granular part
	*/

	("INTERPOLATION: "++interpolate).postln;

	Routine {

		var mAmps, mDurs, mOffs, mAmpRands, mDurRands, mOffRands, phase,
		amp, amp_next, env, env_next, i_env, i_env_next,
		off, off_next,
		amp_out, speed, index, seco_bars, max_samp, min_samp, rate,
		wave;

		max_samp = samp_rate / min_freq;
		min_samp = samp_rate / max_freq;

		seco_bars = [min_samp, max_samp] / n_bpts;

		// have a different way of seeding the inital amp and dur arrays
		phase = 1.0;
		amp = 0.0; amp_next = 0.0;
		i_env = 0; i_env_next = 0.5;
		off = 0;   off_next = 0;
		env = Env.new(); env_next = Env.new();

		mAmpRands = Array.fill(n_bpts, {Pgbrown.new(~max_amp * -1, ~max_amp, step: 0.025).asStream});
		mDurRands = Array.fill(n_bpts, {Pgbrown.new(0.4, 0.7, step: 2).asStream});
		mOffRands = Array.fill(n_bpts, {Pgbrown.new(1, 1024, step: 5).asStream});

		mAmps = Array.fill(n_bpts, {|i| mAmpRands[i].next });
		mDurs = Array.fill(n_bpts, {|i| mDurRands[i].next });
		mOffs = Array.fill(n_bpts, {|i| mOffRands[i].next });

		// use to gather single waveforms
		wave = Array.new();

		index = 0;
		inf.do({
			if (phase >= 1.0, // then move to the next point
				{
					var r;
					phase = phase - 1.0;

					// get the next amplitude
					amp = amp_next;

					// swap envs
					env = env_next;

					if (index == 0 && f.isNil.not, {f.(wave); wave = Array.new()});
					index = (index+1).mod(n_bpts);

					amp_next = mAmpRands[index].next;
					//r = (~amp_rand.rand / 2).rand;
					//amp_next = clip2(mAmps[index] + (r - (r/2)), ~max_amp);
					mAmps[index] = amp_next;

					// how to read through the grain envelope at the
					// correct speed ...m
					env_next = Env.new([0,1,0], [0.5,0.5], curve: \sin);

					off = off_next;
					off_next = mOffRands[index].next;
					mOffs[index] = off_next;

					i_env = i_env_next;
					i_env_next = 0.0;

					rate = mDurRands[index].next;
					mDurs[index] = rate;

					speed = max_freq - min_freq * rate + min_freq * ~freq_mul * (1 / samp_rate) * n_bpts;

					//["NEXT AMP: ", amp_next, "PHASE", phase, "SPEED", speed].postln;
				}
			);

			/*
			| otherwise just continue interpolating between points
			| TODO
			| add other types of interpolation besides linear
			*/

			amp_out = 0.0;
			switch (interpolate,
				\lin, {
					// simple linear interpolation
					amp_out = (1.0 - phase * amp) + (phase * amp_next);
				},
				\cos, {
					var x;
					x = 1 - (phase * pi).cos / 2;
					amp_out = amp * (1 - x) + (amp_next * x);
				},
				\gran, {
					// granular interpolation (also linear too)
					var a,an, x;
					a = amp + (env[i_env] * ~samp[off]);
					an = amp_next + (env_next[i_env_next] * ~samp[off_next]);
					//amp_out = (1.0 - phase * a) + (phase * an)

					x = 1 - (phase * pi).cos / 2;
					amp_out = a * (1 - x) + (an * x);
				},
				{}
			);

			phase = phase + speed;

			i_env = i_env + (speed/2);
			i_env_next = i_env_next + (speed/2);

			off = (off + 1).mod(1024);
			off_next = (off_next + 1).mod(1024);

			wave = wave.add(amp_out);

			// yield the amplitude
			amp_out.yield;
		});
	}
}
)


(
~x = ~ngendy2.(20, interpolate: \gran);
)
(
~w = ~x.asStream();
~w.reset;
~w.next

)
~wave = 400000.collect({~w.next});
~wave.plot

clip2(-0.1,0.7)
(

/* ------------------------------------------------------------------
 * |
 * | VISUAL TESTING PANEL
 * |
 * -----------------------------------------------------------------*/
var curr_routine, gen_wave, n_samples, k_size = 36;

~interpolation_val = \lin;

w = Window("ngendy testing", Rect(0, 0, 880, 540));
w.view.decorator = FlowLayout(w.view.bounds, gap: 1@1);

k = EZKnob(
	w,
	46 @ 74,
	"freq",
	ControlSpec.new(0.5, 2.0),
	{|v,x,y| v.value.postln; ~freq_mul = v.value },
	margin:2@2,
	labelHeight:16
);
k.view.background_(Color.grey.alpha_(0.4));

j = EZKnob(
	w,
	46 @ 74,
	"rand1",
	ControlSpec.new(0.025, 0.5),
	{|v,x,y| v.value.postln; ~amp_rand = v.value },
	margin:2@2,
	labelHeight:16
);
j.view.background_(Color.grey.alpha_(0.4));

l = EZKnob(
	w,
	46 @ 74,
	"rand2",
	ControlSpec.new(0.5, 2.0),
	{|v,x,y| v.value.postln; ~freq_mul = v.value },
	margin:2@2,
	labelHeight:16
);
l.view.background_(Color.grey.alpha_(0.4));

n = EZListView.new(
	w,
	102 @ 72,
	"interpolation",
	[
		'linear'   -> { arg lo; ~interpolation_val = \lin;  },
		'cosine'   -> { arg lo; ~interpolation_val = \cos;  },
		'granular' -> { arg lo; ~interpolation_val = \gran; }
	]
);

b = Button(w, Rect(20, 20, 80, 26))
.states_([
	["run", Color.black, Color.red],
	["stop", Color.black, Color.green]
])
.action_({
	arg b, mod;
	b.value.postln;
	switch (b.value,
		1, {
			"run pressed".postln;
			~run_gendy.(i_val: ~interpolation_val, w: 0.001);
			b.value = 1;
		},
		0, {
			"stop pressed".postln;
			(curr_routine.isNil.not).if { curr_routine.stop } {};
			b.value = 0;
	});
});

g = EZNumber(w,        // parent
	150@20,   // bounds
	" test ", // label
	ControlSpec.new(44800, 2000000),    // controlSpec
	{ |ez| n_samples = ez.value }, // action
	330,      // initValue
	true      // initAction
);
g.setColors(Color.grey,Color.white);

c = Button(w, Rect(20, 20, 80, 26))
.states_([
	["play", Color.white, Color.blue],
])
.action_({
	arg b, mod;
	var buf;
	"playing stored wave".postln;
	buf = Buffer.loadCollection(s, gen_wave, action: {
		{ RLPF.ar(PlayBuf.ar(1, buf, BufRateScale.kr(buf) * 0.6, loop: 0) * 0.5, MouseX.kr(300, 2000)) }.play
	});
});

d = Button(w, Rect(20, 20, 80, 26))
.states_([
	["gennn", Color.black, Color.green],
])
.action_({
	arg b, mod;
	~run_gendy.(i_val: ~interpolation_val, n: n_samples);
});

z = CompositeView(w, Rect(440, 10, 430, 250)).background_(Color.rand(0.7)).resize_(5);
a = Plotter("plot", parent: z).value_([0, 1, 2, 3, 4].scramble * 100);
w.front;

~run_gendy = {
	arg i_val, w=0, n=inf;

	curr_routine = Routine {
		var gen, wave;

		gen = ~ngendy2.(22,
			interpolate: i_val,
			f: { |wave|
				//"full wave".postln;
				//wave.postln;
				if(wave.size > 0, {a.value_(wave)});
		});

		gen_wave = Array.new();
		n.do({
			gen_wave = gen_wave.add(gen.next);
			(w > 0).if {w.wait;};
		});
	};
	curr_routine.play(AppClock);
};

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

(
a = ~wave; // 5 seconds of noise
b = Buffer.loadCollection(s, a);
)

// play it
x = { RLPF.ar(PlayBuf.ar(1, b, BufRateScale.kr(b) * 0.6, loop: 0) * 0.5, MouseX.kr(300, 2000)) }.play;
b.free; x.free;
