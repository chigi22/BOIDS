3 => int numObjects;

LiSa lisaArray[numObjects];
Pan2 pannerArray[numObjects];
SndBuf bufferArray[numObjects];
string fileNameArray[numObjects];
int triggerCountArray[numObjects];
float xCMarray[numObjects];
float yCMarray[numObjects];
LiSa @ lisaRef;

"/Users/chigi22/Documents/School/Flock/BOIDS/ChucK/sounds/01 Fahren.wav" => fileNameArray[0];
"/Users/chigi22/Documents/School/Flock/BOIDS/ChucK/sounds/god_phrase1.wav" => fileNameArray[1];
"/Users/chigi22/Documents/School/Flock/BOIDS/ChucK/sounds/chord.wav" => fileNameArray[2];

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
800 => float screenSize;

while (true) {
    float simParams[6];
    float grainParams[6];
    oe => now;
    while (oe.nextMsg()) {
        // params: subFlockID, x, y, vx, vy, ax, ay
        oe.getFloat() $ int => int subFlockID;
        for (0 => int i; i < 6; i++) {
            oe.getFloat() => simParams[i];
        }
        limitSubFlockID(subFlockID) => subFlockID;
        updateCM(simParams[0],simParams[1],subFlockID);
        mapParams(simParams, subFlockID) @=> grainParams;
        spork ~ grainFlinger(grainParams[0]*1::ms, grainParams[1]*1::ms, grainParams[2]*1::ms, grainParams[3], grainParams[4]*1::ms, grainParams[5], subFlockID);
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

fun float[] mapParams(float simParams[], int subFlockID) {
    // (grainLen, rampUp, rampDown, rate, position, gain)
    float grainParams[6];
    if (subFlockID==0 || subFlockID==1) {
        // rate
        1+0.5*(2*simParams[0]/screenSize-1) => grainParams[3];
        // length
        (simParams[1]/screenSize+0.5)*70 => grainParams[0];
        lisaArray[subFlockID] @=> lisaRef;
        // position
        simParams[1]*(lisaRef.duration()/1::samp)/screenSize => grainParams[4];
        // rampup
        (simParams[0]/screenSize+0.1)*(grainParams[0]*.25) => grainParams[1];
        // rampdown
        (simParams[0]/screenSize+0.1)*(grainParams[0]*.25) => grainParams[2];
        // gain
        (1+simParams[3]/4)*0.3 => grainParams[5];
    }
    if (subFlockID==2) {
        // rate
        1+0.5*(2*simParams[0]/screenSize-1) => grainParams[3];
        // length
        (simParams[1]/screenSize+0.5)*70 => grainParams[0];
        lisaArray[subFlockID] @=> lisaRef;
        // position
        simParams[1]*(lisaRef.duration()/1::samp)/screenSize => grainParams[4];
        // rampup
        (simParams[0]/screenSize+0.1)*(grainParams[0]*.25) => grainParams[1];
        // rampdown
        (simParams[0]/screenSize+0.1)*(grainParams[0]*.25) => grainParams[2];
        // gain
        (1-simParams[3]/4)*0.6 => grainParams[5];
    }
    return grainParams;
}