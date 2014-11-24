SndBuf buf;
LiSa lisa => dac;

// "/Users/chigi22/Desktop/single_comp.wav" => buf.read;
"/Users/chigi22/Desktop/seagulls.wav" =>buf.read;
buf.samples()*1::samp => lisa.duration;
lisa.maxVoices(100);
for (0 => int i; i < buf.samples(); i++) {
    lisa.valueAt(buf.valueAt(i), i::samp);
}
while (true) {
    Math.randomf() => float rando;
    Std.rand2f(0.75,1.25) => float newRate;
    // rando + 0.5 => float newRate
    // Std.rand2f(35, 100)*1::ms => dur newDur;
    (rando*15+30)*1::ms => dur newDur;
    Std.rand2f(0,1)*buf.length() => dur newPos;
    // Std.rand2f(5,15)*1::ms => dur rampUp;
    (rando*5+10)*1::ms => dur rampUp;
    // Std.rand2f(5,15)*1::ms => dur rampDown;
    (rando*5+10)*1::ms => dur rampDown;
    spork ~ getGrain(newDur, rampUp, rampDown, newRate, newPos);
    
    Std.rand2f(2,10)*1::ms => now;
}

fun void getGrain(dur grainLen, dur rampUp, dur rampDown, float rate, dur position) {
    lisa.getVoice() => int newVoice;
    if(newVoice > -1) {
        lisa.rate(newVoice, rate);
        //l.playpos(newvoice, Std.rand2f(0., 1000.) * 1::ms);
        lisa.playPos(newVoice, position);
        //<<<l.playpos(newvoice)>>>;
        lisa.rampUp(newVoice, rampUp);
        (grainLen - (rampUp + rampDown)) => now;
        lisa.rampDown(newVoice, rampDown);
        rampDown => now;
    }
}