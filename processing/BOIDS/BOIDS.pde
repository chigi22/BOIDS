PrintWriter output;
int numBoids = 0;
boolean drawEnable = true;
boolean oscEnable = true;
int frameRateInt = 60;
int screenSize = 750;
float neighborDist = 35;
float borderRepulsionDist = 35;
float repulsionEfficiency = 0.01;
float trigger_radius = 16.0;
float maxspeed = 3; // was 2.25
float maxforce = 0.1; // was 0.04
float r = 3;
int initialBoidCount = 100;
float sepWeight = 1.5;
float cohWeight = 1.25;
float alignWeight = 1;
int currentFlockID = 0;
boolean addBoids = false;
boolean killSubFlock = false;
int subFlockIDtoKill = 0;
int numSubFlocks = 5;
color[] boidColors = new color[numSubFlocks];
color[] circleColors = new color[numSubFlocks];
Flock flock;

import oscP5.*;
import netP5.*;
OscP5 oscP5;
NetAddress myRemoteLocation;

void setup() {
  if (oscEnable) {
    oscP5 = new OscP5(this, 12000);
    myRemoteLocation = new NetAddress("127.0.0.1", 12001);
  }
  size(screenSize, screenSize);
  flock = new Flock();
  frameRate(frameRateInt);
  for (int i = 0; i < numSubFlocks; i++) {
    int R = int(random(200)+55);
    int G = int(random(200)+55);
    int B = int(random(200)+55);
    boidColors[i]=color(R, G, B);
    circleColors[i]=color(R, G, B, 128);
  }
  // Add an initial set of boids into the system
}

void draw() {
  background(50);
  flock.run();
  flock.updateBoids();
}

void keyPressed() {
  if (key == 'q') {
    exit();  // Stops the program
  }
  if (key == 'r') {
    trigger_radius = trigger_radius/2;
  }
  if (key == 'i') {
    trigger_radius = trigger_radius*2;
  }
  if (key == 'd') {
    drawEnable = !drawEnable;
  }
  if (key == 'a') {
    flock.addSubFlock(initialBoidCount, screenSize/2, screenSize/2, currentFlockID);
    currentFlockID++;
  }
  if (key == 'k') {
    if (currentFlockID - 1 >= 1) {
      flock.killSubFlock(currentFlockID-1);
      currentFlockID--;
    }
  }
  if (key == 's') {
    if (cohWeight != 0) {
      cohWeight = 0;
      alignWeight = 0;
    } else {
      cohWeight = 1.25;
      alignWeight = 1;
    }
  }
}

void oscEvent(OscMessage theOscMessage) {
  if (theOscMessage.checkAddrPattern("/boids/addSubFlock")==true) {
    /* check if the typetag is the right one. */
    if (theOscMessage.checkTypetag("iiii")) {
      int myCount = theOscMessage.get(0).intValue();  
      int myX = theOscMessage.get(1).intValue();
      int myY = theOscMessage.get(2).intValue();
      int mySubFlockID = theOscMessage.get(3).intValue();
      flock.addSubFlock(myCount, myX, myY, mySubFlockID);
      return;
    }
  }
  if (theOscMessage.checkAddrPattern("/boids/killSubFlock")==true) {
    /* check if the typetag is the right one. */
    if (theOscMessage.checkTypetag("i")) {
      int mySubFlockID = theOscMessage.get(0).intValue();
      flock.killSubFlock(mySubFlockID);
      return;
    }
  }
  if (theOscMessage.checkAddrPattern("/boids/scatter")==true) {
    /* check if the typetag is the right one. */
    if (theOscMessage.checkTypetag("i")) {
      int scattVal = theOscMessage.get(0).intValue();
      if (scattVal == 1) {
        cohWeight = 0;
        alignWeight = 0;
      } else {
        cohWeight = 1.25;
        alignWeight = 1;
      }
      return;
    }
  }
  if (theOscMessage.checkAddrPattern("/boids/setTrigRad")==true) {
    /* check if the typetag is the right one. */
    if (theOscMessage.checkTypetag("f")) {
      trigger_radius = theOscMessage.get(0).floatValue();
      return;
    }
  }
}

// The Boid class
class Boid {
  int id;
  int mySubFlock;
  PVector trigger_loc;
  PVector location;
  PVector velocity;
  PVector acceleration;
  float mass;
  OscMessage myMessage;

  Boid(float x, float y, int IDin, int subFlockIn) {
    mySubFlock = subFlockIn;
    id = IDin;
    if (oscEnable) {
      myMessage = new OscMessage("/boids");
    }
    location = new PVector(x, y);
    trigger_loc = new PVector(x, y);
    mass = 0.5*(random(1)+1);
    acceleration = new PVector(0, 0);
    // This is a new PVector method not yet implemented in JS
    // velocity = PVector.random2D();
    // Leaving the code temporarily this way so that this example runs in JS
    float angle = random(TWO_PI);
    velocity = new PVector(random(1)*cos(angle), random(1)*sin(angle));
  }

  void run(ArrayList<Boid> boids) {
    flock(boids);
    update();
    borders();
    if (drawEnable) {
      render();
    }
  }

  int getSubFlockID() {
    return mySubFlock;
  }

  void applyForce(PVector force) {
    force.div(mass);
    acceleration.add(force);
  }
  // We accumulate a new acceleration each time based on three rules
  void flock(ArrayList<Boid> boids) {
    PVector sep = separate(boids);   // Separation
    PVector ali = align(boids);      // Alignment
    PVector coh = cohesion(boids);   // Cohesion
    // Arbitrarily weight these forces
    sep.mult(sepWeight);
    ali.mult(alignWeight);
    coh.mult(cohWeight);
    // Add the force vectors to acceleration
    applyForce(sep);
    applyForce(ali);
    applyForce(coh);
  }

  // Method to update location
  void update() {
    // Update velocity
    velocity.add(acceleration);
    // Limit speed
    velocity.limit(maxspeed);
    location.add(velocity);
    if (dist(location.x, location.y, trigger_loc.x, trigger_loc.y) >= trigger_radius) {
      if (oscEnable) {
        myMessage.clear();
        myMessage.setAddrPattern("/boids");
        myMessage.add(new float[] {
          mySubFlock, location.x, location.y, velocity.x, velocity.y, acceleration.x, acceleration.y
        }
        );
        oscP5.send(myMessage, myRemoteLocation);
      }
      trigger_loc.x = location.x;
      trigger_loc.y = location.y;
      if (drawEnable) {
        fill(circleColors[mySubFlock]);
        stroke(circleColors[mySubFlock]);
        ellipse(trigger_loc.x, trigger_loc.y, 2*trigger_radius, 2*trigger_radius);
      }
    }
    // Reset accelertion to 0 each cycle
    acceleration.mult(0);
  }

  // A method that calculates and applies a steering force towards a target
  // STEER = DESIRED MINUS VELOCITY
  PVector seek(PVector target) {
    PVector desired = PVector.sub(target, location);  // A vector pointing from the location to the target
    // Scale to maximum speed
    desired.normalize();
    desired.mult(maxspeed);

    // Above two lines of code below could be condensed with new PVector setMag() method
    // Not using this method until Processing.js catches up
    // desired.setMag(maxspeed);
    // Steering = Desired minus Velocity

    PVector steer = PVector.sub(desired, velocity);
    steer.limit(maxforce);  // Limit to maximum steering force
    return steer;
  }

  void render() {
    // Draw a triangle rotated in the direction of velocity
    float theta = velocity.heading2D() + radians(90);
    // heading2D() above is now heading() but leaving old syntax until Processing.js catches up
    //fill(200, 100);
    fill(boidColors[mySubFlock]);
    stroke(boidColors[mySubFlock]);
    // ellipse(trigger_x, trigger_y, 2*trigger_radius, 2*trigger_radius);
    pushMatrix();
    translate(location.x, location.y);
    rotate(theta);
    beginShape(TRIANGLES);
    vertex(0, -r*2);
    vertex(-r, r*2);
    vertex(r, r*2);
    endShape();
    popMatrix();
  }
  // different border conditions
  // 1) Wraparound
  //    void borders() {
  //      if (location.x < -r) location.x = width+r;
  //      if (location.y < -r) location.y = height+r;
  //      if (location.x > width+r) location.x = -r;
  //      if (location.y > height+r) location.y = -r;
  //  }
  // 2) Bounce (elastic)
  //  void borders() {
  //    if (location.x < -r) {
  //      location.x = -r;
  //      velocity.x = -velocity.x;
  //    }
  //    if (location.y < -r) {
  //      location.y = -r; 
  //     velocity.y = -velocity.y;
  //   }
  //    if (location.x > width+r) {
  //      location.x = width+r;
  //      velocity.x = -velocity.x;
  //    }
  //    if (location.y > height+r) {
  //      location.y = height+r;
  //      velocity.y = -velocity.y;
  //    }
  //  }

  // 3. repulsive (perhaps try a 1/r^2 coulomb-like repulsion)
  void borders() {
    if (location.x < borderRepulsionDist) {
      velocity.x = velocity.x + (borderRepulsionDist - location.x) * repulsionEfficiency;
    }
    if (location.y < borderRepulsionDist) {
      velocity.y = velocity.y + (borderRepulsionDist - location.y) * repulsionEfficiency;
    }
    if (location.x > width - borderRepulsionDist) {
      velocity.x = velocity.x + (width - borderRepulsionDist - location.x) * repulsionEfficiency;
    }
    if (location.y > height - borderRepulsionDist) {
      velocity.y = velocity.y + (height - borderRepulsionDist - location.y) * repulsionEfficiency;
    }
  }

  // Separation
  // Method checks for nearby boids and steers away
  PVector separate (ArrayList<Boid> boids) {
    float desiredseparation = 20.0f;
    PVector steer = new PVector(0, 0, 0);
    int count = 0;
    // For every boid in the system, check if it's too close
    for (Boid other : boids) {
      float d = PVector.dist(location, other.location);
      // If the distance is greater than 0 and less than an arbitrary amount (0 when you are yourself)
      if ((d > 0) && (d < desiredseparation)) {
        // Calculate vector pointing away from neighbor
        PVector diff = PVector.sub(location, other.location);
        diff.normalize();
        diff.div(d);        // Weight by distance
        steer.add(diff);
        count++;            // Keep track of how many
      }
    }
    // Average -- divide by how many
    if (count > 0) {
      steer.div((float)count);
    }
    // As long as the vector is greater than 0
    if (steer.mag() > 0) {
      // First two lines of code below could be condensed with new PVector setMag() method
      // Not using this method until Processing.js catches up
      // steer.setMag(maxspeed);

      // Implement Reynolds: Steering = Desired - Velocity
      steer.normalize();
      steer.mult(maxspeed);
      steer.sub(velocity);
      steer.limit(maxforce);
    }
    return steer;
  }

  // Alignment
  // For every nearby boid in the system, calculate the average velocity
  PVector align (ArrayList<Boid> boids) {
    PVector sum = new PVector(0, 0);
    int count = 0;
    for (Boid other : boids) {
      float d = PVector.dist(location, other.location);
      if ((d > 0) && (d < neighborDist)) {
        sum.add(other.velocity);
        count++;
      }
    }
    if (count > 0) {
      sum.div((float)count);
      // First two lines of code below could be condensed with new PVector setMag() method
      // Not using this method until Processing.js catches up
      // sum.setMag(maxspeed);

      // Implement Reynolds: Steering = Desired - Velocity
      sum.normalize();
      sum.mult(maxspeed);
      PVector steer = PVector.sub(sum, velocity);
      steer.limit(maxforce);
      return steer;
    } else {
      return new PVector(0, 0);
    }
  }

  // Cohesion
  // For the average location (i.e. center) of all nearby boids, calculate steering vector towards that location
  PVector cohesion (ArrayList<Boid> boids) {
    PVector sum = new PVector(0, 0);   // Start with empty vector to accumulate all locations
    int count = 0;
    for (Boid other : boids) {
      float d = PVector.dist(location, other.location);
      if ((d > 0) && (d < neighborDist)) {
        sum.add(other.location); // Add location
        count++;
      }
    }
    if (count > 0) {
      sum.div(count);
      return seek(sum);  // Steer towards the location
    } else {
      return new PVector(0, 0);
    }
  }
}

// The Flock (a list of Boid objects)
class Flock {
  // how can I change data structure to make things like killSubFlock smarter?
  ArrayList<Boid> boids; // An ArrayList for all the boids
  ArrayList<Boid> boidsToAdd;
  Flock() {
    boids = new ArrayList<Boid>(); // Initialize the ArrayList
    boidsToAdd = new ArrayList<Boid>();
  }

  void run() {
    for (Boid b : boids) {
      b.run(boids);  // Passing the entire list of boids to each boid individually
    }
  }

  void addBoid(Boid b) {
    addBoids = true;
    boidsToAdd.add(b);
  }

  void updateBoids() {
    if (addBoids) {
      for (int i = 0; i < boidsToAdd.size (); i++) {
        boids.add(boidsToAdd.get(i));
      }
      boidsToAdd.clear();
      addBoids = false;
    }
    if (killSubFlock) {
      for (int i = boids.size ()-1; i>=0; i--) {
        Boid b = boids.get(i);
        if (b.getSubFlockID() == subFlockIDtoKill) {
          boids.remove(i);
        }
      }
      killSubFlock = false;
    }
  }

  void addSubFlock(int count, int x, int y, int subFlockID) {
    for (int i = 0; i < count; i++) {
      flock.addBoid(new Boid(x, y, numBoids + i, subFlockID));
    }
    numBoids += count;
  }

  void killSubFlock(int flockID) {
    killSubFlock = true;
    subFlockIDtoKill = flockID;
  }
}

