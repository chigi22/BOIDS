// create our OSC receiver
OscRecv recv;
// use port 6449 (or whatever)
12001 => recv.port;
// start listening (launch thread)
recv.listen();
// create an address in the receiver, store in new variable
recv.event( "/boids, f f f f f f f" ) @=> OscEvent @ oe;
// infinite event loop
while( true )
{
    // wait for event to arrive
    oe => now;
    // grab the next message from the queue. 
    while( oe.nextMsg() )
    { 
        float id, x, y, vx, vy, ax, ay;
        
        // getFloat fetches the expected float (as indicated by "i f")
        oe.getFloat() => id;
        oe.getFloat() => x;
        oe.getFloat() => y;
        oe.getFloat() => vx;
        oe.getFloat() => vy;
        oe.getFloat() => ax;
        oe.getFloat() => ay;
        // print
        <<< "got (via OSC):", id, x, y, vx, vy, ax, ay >>>;
    }
}