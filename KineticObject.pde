public class KineticObject {
  long age;      //age in millis
  boolean dead;
  
  PVector pos;   //position
  PVector vel;   //velocity
  PVector acc;   //acceleration 
  float friction;    //friction

  float angAcc;  //angular acceleration
  float angVel;  //angular velocity
  float ang;     //angle/forward direction
  float angFriction; //angular friction
  
  public KineticObject() {
    age = 0;
    dead = false;
    
    pos = new PVector();
    acc = new PVector();
    vel = new PVector();

    ang = 0;
    angAcc = 0;
    angVel = 0;
    
    //default to no friction
    friction = 1;
    angFriction = 1;
  }
  
  //update
  public void update(long dt) {
    //grow old
    age += dt;
    
    //apply motion
    move();
  }

  //move
  public void move() {
    //apply acceleration
    vel.x += acc.x;
    vel.y += acc.y;
    vel.z += acc.z;
    acc.x = acc.y = acc.z = 0;
    
    //apply friction
    vel.mult(friction);   
    
    //apply velocity
    pos.add(vel);
    
    //apply angular acceleration
    angVel += angAcc;
    angAcc = 0;
    
    //apply friction
    angVel *= angFriction; 
    
    //apply angular velocity
    ang += angVel;
  }
  
  //apply force
  public void push(float x, float y, float z) {
    acc.x += x;
    acc.y += y;
    acc.z += z;
  }
  
  //apply force
  public void push(PVector v) {
    acc.x += v.x;
    acc.y += v.y;
    acc.z += v.z;
  }
  
  //apply angular force
  public void spin(float f) {
    angAcc += f;
  }
  
  //set position
  public void setPos(PVector v) { pos.x = v.x; pos.y = v.y; pos.z = v.z; }
  public void setPos(float x, float y, float z) { pos.x = x; pos.y = y; pos.z = z; }
  
  //set friction
  public void setFriction(float f, float af) {
    friction = f;
    angFriction = af;
  }
  
  //get age
  public long age() { return age; }
  
  public void kill() { 
    dead = true;
    angAcc = angVel = 0;
    acc.set(0, 0, 0);
    vel.set(0, 0, 0);
    age = 0;
  }
  
  public boolean isDead() { return dead; } 
}
