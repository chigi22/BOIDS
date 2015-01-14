5 => int numObjects;

LiSa lisaArray[numObjects];
Pan2 pannerArray[numObjects];
SndBuf bufferArray[numObjects];
string fileNameArray[numObjects];
int triggerCountArray[numObjects];
float xCMarray[numObjects];
float yCMarray[numObjects];
Envelope envArray[numObjects];

LiSa @ lisaRef;
float simParams[6];
float grainParams[6];
750 => float screenSize;
3 => float vMax;
1.25 => float gainFactor;

[1.0000, 1.0749, 1.2599, 1.3543, 1.4557, 1.5646, 1.8340] @=> float pelog[];


// modulator
SinOsc m => blackhole;
10 => float mf => m.freq;

me.sourceDir() + "/sounds/godnote.wav" => fileNameArray[0];
me.sourceDir() + "/sounds/godnote2.wav" => fileNameArray[1];
me.sourceDir() + "/sounds/fahrenclip.wav" => fileNameArray[2];
me.sourceDir() + "/sounds/compShort1.wav" => fileNameArray[3];
me.sourceDir() + "/sounds/kingVersionclip.wav" => fileNameArray[4];

for (0=> int i; i < numObjects; i++) {
    lisaArray[i] => envArray[i] => pannerArray[i] => dac;
    1::second $ dur => envArray[i].duration;
    1 => envArray[i].target;
    lisaArray[i].maxVoices(75);
    fileNameArray[i] => bufferArray[i].read;
    bufferArray[i].samples()*1::samp => lisaArray[i].duration;
    for (0 => int j; j < bufferArray[i].samples(); j++) {
        lisaArray[i].valueAt(bufferArray[i].valueAt(j), j::samp);
    }
}

OscRecv recv;
12001 => recv.port;
OscSend xmit;
xmit.setHost("localhost", 12000);
// start listening (launch thread)
recv.listen();
recv.event( "/boids, f f f f f f f" ) @=> OscEvent @ oe;

(screenSize*Math.randomf()) $ int => int xPos1;
(screenSize*Math.randomf()) $ int => int yPos1;
(screenSize*Math.randomf()) $ int => int xPos2;
(screenSize*Math.randomf()) $ int => int yPos2;
setTrigRad(16);
5 => float subFlock1EnvTime;
subFlock1EnvTime::second $ dur => envArray[1].duration;
envArray[1].keyOn();
addSubFlock(25, xPos1, yPos1, 1);
addSubFlock(25, xPos2, yPos2, 1);

doGrainyThings(15);

2 => float subFlock0EnvTime;
subFlock0EnvTime::second $ dur => envArray[0].duration;
envArray[0].keyOn();
addSubFlock(40, 300, 300, 0);

doGrainyThings(20);
scatter(1);
doGrainyThings(10);
scatter(0);
doGrainyThings(7);

5 => float subFlock4EnvTime;
subFlock4EnvTime::second $ dur => envArray[4].duration;
envArray[4].keyOn();
addSubFlock(75, 300, 300, 4);

doGrainyThings(10);

envArray[1].keyOff();
doGrainyThings(subFlock1EnvTime);
killSubFlock(1);

doGrainyThings(10);

5 => float subFlock2EnvTime;
subFlock2EnvTime::second $ dur => envArray[2].duration;
envArray[2].keyOn();
addSubFlock(35, 100, 700, 2);
envArray[0].keyOff();
doGrainyThings(subFlock0EnvTime);
killSubFlock(0);

doGrainyThings(15);

envArray[4].keyOff();
doGrainyThings(subFlock4EnvTime);
killSubFlock(4);
doGrainyThings(1);

addSubFlock(60, 100, 700, 2);
scatter(1);
doGrainyThings(13);
scatter(0);
setTrigRad(48);
doGrainyThings(5);
setTrigRad(32);
doGrainyThings(5);
setTrigRad(16);
doGrainyThings(5);

8 => float subFlock3EnvTime;
subFlock3EnvTime::second $ dur => envArray[3].duration;
envArray[3].keyOn();
addSubFlock(75, 300, 300, 3);

doGrainyThings(20);

envArray[2].keyOff();
doGrainyThings(subFlock2EnvTime);
killSubFlock(2);

setTrigRad(12);
doGrainyThings(20);
envArray[3].keyOff();
doGrainyThings(subFlock3EnvTime);
killSubFlock(3);

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
    if (triggerCountArray[subFlockID] > 25) {
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
    if (subFlockID==0) {
        // rate
        (simParams[3]/2) => grainParams[3];
        // chooseRate(pelog,Std.fabs(simParams[2]/vMax)) => grainParams[3];
        // length
        (simParams[1]/screenSize+0.7)*75 => grainParams[0];
        lisaArray[subFlockID] @=> lisaRef;
        // position
        (simParams[0]/screenSize)*(lisaRef.duration()/1::samp) => grainParams[4];
        // rampup
        (simParams[4]/2+1)*(grainParams[0]*.33) => grainParams[1];
        // rampdown
        (simParams[5]/2+1)*(grainParams[0]*.33) => grainParams[2];
        // gain
        gainFactor*(0.8+simParams[4])*0.5 => grainParams[5];
        //(1+simParams[3]/4)*0.3 => grainParams[5];
    }
    if (subFlockID==1) {
        // rate
        (simParams[3]/2) => grainParams[3];
        // chooseRate(pelog2,Std.fabs(simParams[3]/vMax)) => grainParams[3];
        // length
        (simParams[1]/screenSize+0.7)*75 => grainParams[0];
        lisaArray[subFlockID] @=> lisaRef;
        // position
        (simParams[0]/screenSize)*(lisaRef.duration()/1::samp) => grainParams[4];
        // rampup
        (simParams[4]/2+1)*(grainParams[0]*.33) => grainParams[1];
        // rampdown
        (simParams[5]/2+1)*(grainParams[0]*.33) => grainParams[2];
        // gain
        gainFactor*(1.7+simParams[2]/4)*0.08 => grainParams[5];
        //(1+simParams[3]/4)*0.3 => grainParams[5];
    }
    if (subFlockID==3) {
        // rate
        // (1+3*simParams[4]* m.last()) => grainParams[3];
        chooseRate(pelog,Std.fabs(simParams[3]/vMax)) => grainParams[3];
        //(1+5*m.last()*(Math.fabs(simParams[4])+Math.fabs(simParams[5]))) => grainParams[3];
        ///<<<grainParams[3]>>>;
        // length
        (simParams[0]/screenSize+1)*50 => grainParams[0];
        lisaArray[subFlockID] @=> lisaRef;
        // position
        simParams[1]*(lisaRef.duration()/1::samp)/screenSize => grainParams[4];
        // rampup
        (0.5*simParams[0]/screenSize+0.5)*(grainParams[0]*.33) => grainParams[1];
        // <<<grainParams[1]>>>;
        // rampdown
        (0.5*simParams[1]/screenSize+0.5)*(grainParams[0]*.33) => grainParams[2];
        // gain
        //(1-simParams[4]/4)*0.75 => grainParams[5];
        gainFactor*(1-0.8*simParams[1]/screenSize)*0.1 => grainParams[5];
    }
    if (subFlockID==2) {
        // rate
        1+6*simParams[5] => grainParams[3];
        // length
        (simParams[1]/screenSize+0.5)*75 => grainParams[0];
        lisaArray[subFlockID] @=> lisaRef;
        // position
        simParams[1]*(lisaRef.duration()/1::samp)/screenSize => grainParams[4];
        // rampup
        (simParams[0]/screenSize+0.1)*(grainParams[0]*.33) => grainParams[1];
        // rampdown
        (simParams[3]/screenSize+0.1)*(grainParams[0]*.33) => grainParams[2];
        // gain
        // gainFactor*1.1*simParams[5] => grainParams[5];
        gainFactor*(simParams[5] + 0.025) => grainParams[5];
        // <<< simParams[4], simParams[5] >>>;
    }
    if (subFlockID==4) {
        // rate
        2.1*chooseRate(pelog,Std.fabs(simParams[3]/vMax)) => grainParams[3];
        // chooseRate(pelog,Std.fabs(simParams[2]/vMax)) => grainParams[3];
        // length
        (simParams[1]/screenSize+0.7)*150 => grainParams[0];
        lisaArray[subFlockID] @=> lisaRef;
        // position
        (simParams[0]/screenSize)*(lisaRef.duration()/1::samp) => grainParams[4];
        // rampup
        (grainParams[0]*.33) => grainParams[1];
        // rampdown
        (grainParams[0]*.33) => grainParams[2];
        // gain
        gainFactor*(0.8+simParams[5])*0.20 => grainParams[5];
        //(1+simParams[3]/4)*0.3 => grainParams[5];
    }
    return grainParams;
}

fun void doGrainyThings(float duration) {
    now + duration::second => time later;
    while (now < later) {
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
}

fun void addSubFlock(int count, int xPos, int yPos, int subFlockID) {
    xmit.startMsg( "/boids/addSubFlock", "iiii" );
    count => xmit.addInt;
    xPos => xmit.addInt;
    yPos => xmit.addInt;
    subFlockID => xmit.addInt;
    <<< "add">>>;
}

fun void killSubFlock(int subFlockID) {
    xmit.startMsg( "/boids/killSubFlock", "i" );
    subFlockID => xmit.addInt;
    <<< "kill">>>;
}

fun void scatter(int val) {
    xmit.startMsg( "/boids/scatter", "i" );
    val => xmit.addInt;
    <<< "scatter">>>;
}

fun float chooseRate(float scale[], float num) {
    if (num < 0) {
        0 => num;
    }
    if (num > 1) {
        1 => num;
    }
    ((scale.cap() - 1) * num) $ int => int ind;
    scale[ind]/scale[0] => float result;
    return result;
}

fun void setTrigRad(float trigRad) {
    xmit.startMsg( "/boids/setTrigRad", "f" );
    trigRad => xmit.addFloat;
    <<< "set trigger radius">>>;
}