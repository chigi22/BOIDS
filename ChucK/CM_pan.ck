SndBuf buf;
LiSa lisa => pan2 p => dac;
// create our OSC receiver
OscRecv recv;
// use port 6449 (or whatever)
12001 => recv.port;
// start listening (launch thread)
recv.listen();
// create an address in the receiver, store in new variable
recv.event( "/boids, f f f f f f f" ) @=> OscEvent @ oe;
900 => float screenSize;
0 => float x_CM;
0 => float N;

"/Users/chigi22/Desktop/01 Fahren.wav" => buf.read;
buf.samples()*1::samp => lisa.duration;
lisa.maxVoices(100);
for (0 => int i; i < buf.samples(); i++) {
    lisa.valueAt(buf.valueAt(i), i::samp);
}
while (true) {
    // Std.rand2f(0.75,1.25) => float newRate;
    // Std.rand2f(50, 75)*1::ms => dur newDur;
    // Std.rand2f(0,1)*buf.length() => dur newPos;
    // Std.rand2f(5,25)*1::ms => dur rampUp;
    // Std.rand2f(5,25)*1::ms => dur rampDown;
    // spork ~ getGrain(newDur, rampUp, rampDown, newRate, newPos);
    // 3::ms => now;
    oe => now;
    while (oe.nextMsg())
    {
        float x, y, vx, vy;
        // getFloat fetches the expected float (as indicated by "i f")
        oe.getFloat() $ int => int id;
        oe.getFloat() => x;
        oe.getFloat() => y;
        oe.getFloat() => vx;
        oe.getFloat() => vy;
        if (N > 20) {
            2*(x_CM/screenSize-0.5) => p.pan;
            0 => N;
            0 => x_CM;
        }
        (N*x_CM+x)/(N+1) => x_CM;
        N+1 => N;
        (x/screenSize)*0.5+0.75 => float newRate;
        (y/screenSize+0.5)*30::ms => dur newDur;
        y*buf.length()/screenSize => dur newPos;
        (x/screenSize+0.1)*(newDur*.25) => dur rampUp;
        (x/screenSize+0.1)*(newDur*.25) => dur rampDown;
        (1+vy/8)*0.4 => float newGain;
        spork ~ grainFlinger(newDur, rampUp, rampDown, newRate, newPos, newGain, x_CM);//, id);
    }
}

fun void grainFlinger(dur grainLen, dur rampUp, dur rampDown, float rate, dur position, float gain, float x_pos){//, int newVoice) {
    lisa.getVoice() => int newVoice;
    if(newVoice > -1) {
        lisa.voiceGain(newVoice, gain);
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