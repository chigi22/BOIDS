4 => int numObjects;

LiSa lisaArray[numObjects];
Pan2 pannerArray[numObjects];
SndBuf bufferArray[numObjects];
string fileNameArray[numObjects];
int triggerCountArray[numObjects];
float xCMarray[numObjects];
float yCMarray[numObjects];
LiSa @ lisaRef;

"/Users/chigi22/Desktop/01 Fahren.wav" => fileNameArray[0];
"/Users/chigi22/Desktop/seagulls.wav" => fileNameArray[1];
"/Users/chigi22/Desktop/03 God Bless the Child.wav" => fileNameArray[2];
"/Users/chigi22/Desktop/single_comp.wav" => fileNameArray[3];

for (0=> int i; i < numObjects; i++) {
    lisaArray[i] => pannerArray[i] => dac;
    lisaArray[i].maxVoices(50);
    fileNameArray[i] => bufferArray[i].read;
    bufferArray[i].samples()*1::samp => lisaArray[i].duration;
    for (0 => int j; j < bufferArray[i].samples(); j++) {
        lisaArray[i].valueAt(bufferArray[i].valueAt(j), j::samp);
    }
}

OscRecv recv;
12001 => recv.port;
// start listening (launch thread)
recv.listen();
recv.event( "/boids, f f f f f f f" ) @=> OscEvent @ oe;
900 => float screenSize;

while (true) {
    oe => now;
    while (oe.nextMsg())
    {
        // how can I generalize this?
        float x, y, vx, vy, ax, ay;
        oe.getFloat() $ int => int subFlockID;
        oe.getFloat() => x;
        oe.getFloat() => y;
        oe.getFloat() => vx;
        oe.getFloat() => vy;
        oe.getFloat() => ax;
        oe.getFloat() => ay;
        limitSubFlockID(subFlockID) => subFlockID;
        updateCM(x,y,subFlockID);
        (x/screenSize)*0.5+0.75 => float newRate;
        (y/screenSize+0.5)*30::ms => dur newDur;
        lisaArray[subFlockID] @=> lisaRef;
        y*(lisaRef.duration())/screenSize => dur newPos;
        (x/screenSize+0.1)*(newDur*.25) => dur rampUp;
        (x/screenSize+0.1)*(newDur*.25) => dur rampDown;
        (1+vy/8)*0.4 => float newGain;
        spork ~ grainFlinger(newDur, rampUp, rampDown, newRate, newPos, newGain, subFlockID);
    }
}

// re-work this to just take a reference to the lisa object to make more generic
fun void grainFlinger(dur grainLen, dur rampUp, dur rampDown, float rate, dur position, float gain, int subFlockID){
    lisaArray[subFlockID].getVoice() => int newVoice;
    if(newVoice > -1) {
        lisaArray[subFlockID].voiceGain(newVoice, gain);
        lisaArray[subFlockID].rate(newVoice, rate);
        lisaArray[subFlockID].playPos(newVoice, position);
        lisaArray[subFlockID].rampUp(newVoice, rampUp);
        (grainLen - (rampUp + rampDown)) => now;
        lisaArray[subFlockID].rampDown(newVoice, rampDown);
        rampDown => now;
    }
}

fun void updateCM(float x, float y, int subFlockID) {
    if (triggerCountArray[subFlockID] > 20) {
        2*(xCMarray[subFlockID]/screenSize-0.5) => pannerArray[subFlockID].pan;
        0 => triggerCountArray[subFlockID];
        0 => xCMarray[subFlockID];
    }
    (triggerCountArray[subFlockID]*xCMarray[subFlockID]+x)/(triggerCountArray[subFlockID]+1) => xCMarray[subFlockID];
    (triggerCountArray[subFlockID]*yCMarray[subFlockID]+y)/(triggerCountArray[subFlockID]+1) => yCMarray[subFlockID];
    triggerCountArray[subFlockID]+1 => triggerCountArray[subFlockID];
}

fun int limitSubFlockID(int subFlockID) {
    if (subFlockID >= numObjects) {
        numObjects -1 => subFlockID;
    }
    if (subFlockID < 0) {
        0 => subFlockID;
    }
    return subFlockID;
}