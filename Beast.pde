/**
 * Squid-like beast.
 
 Copyright (C) <2015>  <Jason Lewis>
  
    This program is free software: you can redistribute it and/or modify
    it under the terms of the BSD 3 clause with added Attribution clause license.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   BSD 3 clause with added Attribution clause License for more details.
 */
public class Beast {
  long age;                 //age
  int id;                   //unique integer id

  float speed;              //speed multiplier
  float offsetAngle;        //angle offset for scatter behavior to work with current

  PImage shadow;            //shadow image
  TessData[] origText;      //tesselated data of the original text
  TessData[] dfrmText;      //tesselated data of the deformed text

  PVector pos;              //position
  PVector vel;              //velocity
  PVector acc;              //acceleration
  float rot;                //rotation
  float rotAcc;             //angular acceleration
  float rotVel;             //angular velocity
  float targetRot;          //target rotation
  float forward;            //forward direction

  PVector mouth;            //center of lens effect
  float origMagnification;  //original magnification
  float magnification;      //current magnification
  float magOffset;          //magnification animation period offset
  float radius;             //lens radius
  float targetRadius;       //target lens radius (to animate on touch)

  PVector tail;             //control point for the tailing text (used for DEBUG)
  
  float scatter;            //scatter factor
  float camouflage;         //opacity offset to highlight the beast
  float scatterOffset;      //offset z value to calculate perlin noise effect of scatter
  
  String[] tokens;          //split string tokens (for spray)
  int firstTokenIndex;      //first index of consecutive spray
  int tokenIndex;           //current index of token to spray
  int tokenLoop;            //number of times the beast sprayed its whole string
  long lastSpray;           //last time we sprayed
  
  static final float ATTENUATION = 0.95f;            //motion attenuation factor
  static final float ANGULAR_ATTENUATION = 0.980f;   //rotation attenuation
  static final float BREATHING_SPEED = 750f;         //breathing (scaling) spread
  static final float BREATHING_SCALE = 0.07f;        //breathing scale (magnitude)
  static final float APPROACH_SPEED = 0.8f;          //speed to approach to touch
  static final int APPROACH_THRESHOLD = 25;          //approach threshold distance (hit distance)
  static final float CURRENT_STRENGTH = 0.2f;        //strength of current
  static final float SCATTER_STRENGTH = 0.65f;       //strength of scatter behavior
  static final float SCATTER_ATTENUATION = 0.03f;    //attenuation of scatter behavior
  static final float TAIL_BEND_FACTOR = 250;         //bend factor for the tail behavior
  static final int SPRAY_INTERVAL = 750;             //interval (millis) between sprayed words
  static final int SPRAY_LOOP_INTERVAL = 2500;       //interval (millis) between last and first sprayed word
  static final int SPRAY_FORCE = 50;                 //release force of sprayed words
  static final float SPRAY_ANGULAR_FORCE = 0.25f;    //angular release force of sprayed words; 50
  static final float TESS_DETAIL_MIN = 1.0;          //minimum tesselation detail
  static final float TESS_DETAIL_MAX = 3.0;          //maximum tesselation detail
  static final float CAMOUFLAGE_MULTIPLIER = 75f;    //amount of opacity change by camouflage
  static final float CAMOUFLAGE_RATE = 0.05f;        //rate at which camouflage increases/decreases
  static final int CAMOUFLAGE_RED = 200;             //red value of camouflage
  static final int CAMOUFLAGE_BLUE = 245;            //blue value of camouflage
  static final int CAMOUFLAGE_GREEN = 230;           //green value of camouflage
  static final int CAMOUFLAGE_ALPHA = 80;            //alpha value of camouflage
  static final float RADIUS_RATE = 5;                //rate at which the radius gets adjusted
  
  //deformation utils
  TessData origData, dfrmData;          //tesselation data
  PVector mouthDelta = new PVector();   //delta betwnee vertex and to mouth
  float[] pOrig, p;                     //vertices
  float mouthDist;                      //distance to mouth
  float scaleFactor;                    //scale factor
  float newdx, newdy;                   //new vertices delta values
  PVector screenPos = new PVector();    //screen position (updated in the draw function)

  //constructor
  public Beast(PVector p) {
    //init
    shadow = null;
    mouth = new PVector();
    tail = new PVector(350, 0, 0);
    setMagnification(0, 0);
    setRadius(0);
    age = 0;
    setSpeed(0.12f);
    scatter = 0;
    scatterOffset = 0;
    camouflage = 0;
    
    tokens = null;
    tokenIndex = 0;
    tokenLoop = 0;
    lastSpray = -SPRAY_INTERVAL;
    
    setPosition(p);
    setVelocity(new PVector());
    setAcceleration(new PVector());
    forward = PI;
    rot = PI;
    rotAcc = 0;
    rotVel = 0;
    
    //apply scatter and calculate the offset angle to help the beast
    //move in the current's direction as much as possible
    applyScatter(1);
    offsetAngle = atan2(height/2 - p.y, width/2 - p.x) - atan2(acc.y, acc.x);
    setAcceleration(new PVector());
  }

  //get position
  PVector getPosition() { return pos; }

  //set position
  void setPosition(PVector p) { pos = p.get(); }

  //set velocity
  void setVelocity(PVector v) { vel = v.get(); }
  
  //set acceleartion
  void setAcceleration(PVector a) { acc = a.get(); }
  
  //set forward angle
  void setForward(float f) { forward = f; }

  //decreases camouflage
  void decCamouflage() {
    if (camouflage == 0) return;
    camouflage -= CAMOUFLAGE_RATE;
    if (camouflage < 0) camouflage = 0;
  }
  
  //increases camouflage
  void incCamouflage() {
    if (camouflage == 1) return;
    camouflage += CAMOUFLAGE_RATE;
    if (camouflage > 1) camouflage = 1;
  }

  //apply random scatter behavior
  void scatter() {
    setScatter(random(0.8, 1.0));
    scatterOffset = random(0, 1000); //change scatter offset to show effect every time
  }
  
  //apply scatter behavior
  void setScatter(float s) { scatter = s; }
  
  //set magnification factor and period offset
  void setMagnification(float mag, float offset) {
    origMagnification = magnification = mag;
    magOffset = offset;
  }
  
  //get magnification factor
  float getMagnification() { return magnification; }
  
  //set speed
  void setSpeed(float s) { speed = s; }
  
  //set/get radius
  void setRadius(float r) { radius = targetRadius = r; }
  void setTargetRadius(float r) { targetRadius = r; }
  float getRadius() { return radius; }
  
  //get mouth
  PVector getMouth() { return mouth; }
  
  //set tail
  void setTail(PVector v) { tail = v.get(); }
  
  //set text string
  void setText(String t) { tokens = t.split(" "); }
 
  //set the original text from NextText and tesselate it
  void setOriginalText(TextObjectGroup root) {
    origText = tesselate(root);
    dfrmText = new TessData[origText.length];
    for(int i = 0; i < dfrmText.length; i++)
      dfrmText[i] = origText[i].clone();
  }
  
  //get the beast's position on the screen
  PVector getScreenPos() { return screenPos; }
  
  float distToPoint(float x, float y) {
    //get the distance to the beasty
    PVector screenPos = getScreenPos();
    float dx = screenPos.x - x;
    float dy = screenPos.y - y;
    float d = sqrt(dx*dx + dy*dy) - radius;
    return d < 0 ? 0 : d;
  }
  
  //update the beast
  void update(long dt) {
    //grow old
    age += dt;

    //adjust magnification factor
    magnification = origMagnification + cos(age/BREATHING_SPEED + magOffset)*BREATHING_SCALE;
    
    //slowly decrease scatter factor
    if (scatter > 0) {
      scatter -= SCATTER_ATTENUATION / dt;
      if (scatter < 0) scatter = 0;
    }
    
    //adjust the radius if necessary
    if (radius != targetRadius) {
      float rd = targetRadius - radius;
      int dir = rd < 0 ? -1 : 1;
      if (rd*dir < RADIUS_RATE) radius = targetRadius;
      else radius += RADIUS_RATE * dir;
    }
    
    //apply acceleration
    applyAcceleration();
    
    //apply velocity
    applyVelocity();
    
    //update the mouth position
    mouth.x = cos( rot ) * radius/20;
    mouth.y = sin( rot ) * radius/20;

    //deform behaviour (lens + tail)
    deform();
  }
  
  //swim behavior
  void swim() {
    applyCurrent(current, 1-scatter);
    applyScatter(scatter);
  }

  //deform behaviour (lens + tail)
  void deform() {
    float a;
    float rtfX, rtfY;
    
    //go through glyphs
    for(int i = 0; i < origText.length; i++) {
      origData = origText[i];
      dfrmData = dfrmText[i];
      
      //go through contours
      for(int j = 0; j < origData.types.length; j++) {

        // Traverse the control points of the glyph, applying the
        // multiplication factor to each one, but offset from the center, not
        // the position.
        for(int k = (j==0?0:origData.ends[j-1]); k < origData.ends[j]; k++) {
          
          // Get the control point position.
          pOrig = origData.vertices[k];
          p = dfrmData.vertices[k];
      
          // mouth delta
          mouthDelta.x = mouth.x - pOrig[0];
          mouthDelta.y = mouth.y - pOrig[1];
          mouthDist = mouthDelta.mag();
          
          //lens
          scaleFactor = radius - (radius - 1) / (mouthDist + 1);
      
          if ( mouthDist != 0.0 )
          {
            newdx = -mouthDelta.x + (magnification * -mouthDelta.x / mouthDist) * scaleFactor;
            newdy = -mouthDelta.y + (magnification * -mouthDelta.y / mouthDist) * scaleFactor;
          }
          else
          {
            newdx = -mouthDelta.x;
            newdy = -mouthDelta.y;
          }
          
          //tail
          a = newdx / TAIL_BEND_FACTOR;
          a *= a;
          a *= -rotVel;
        
          newdx -= mouth.x;
          newdy -= mouth.y;
          rtfX = newdx * cos(a) - newdy * sin(a);
          rtfY = newdx * sin(a) + newdy * cos(a);
          newdx = rtfX + mouth.x;
          newdy = rtfY + mouth.y;

          dfrmData.vertices[k][0] = pOrig[0] + newdx + mouthDelta.x;
          dfrmData.vertices[k][1] = pOrig[1] + newdy + mouthDelta.y;
        }
      }
    }  
  }
  
  //approach towards x,y point
  void approach(float x, float y) {
    //get screen position
    PVector spos = new PVector(screenX(pos.x, pos.y, pos.z),
                               screenY(pos.x, pos.y, pos.z),
                               0);
                         
    //calculate distance to point                           
    float dx = x - spos.x;
    float dy = y - spos.y;   
    float d = sqrt(dx*dx + dy*dy);
    
    if (d > APPROACH_THRESHOLD) {
      acc.x += dx/d * APPROACH_SPEED;
      acc.y += dy/d * APPROACH_SPEED;
    }
  }
 
  //sprays the next word from the string
  KineticString spray() {
    if (age-lastSpray > SPRAY_INTERVAL*2)
      firstTokenIndex = tokenIndex;
    else if (tokenIndex < firstTokenIndex)
       firstTokenIndex = tokenIndex;
      
    return spray(PI+(tokenIndex-firstTokenIndex)*PI/16, 1+0.5*(tokenIndex-firstTokenIndex+1), false); 
  }
  
  KineticString spray(float pushAngle, float pushForce, boolean override) {
    //do nothing if the last spray was too recent
    if (!override && age-lastSpray < SPRAY_INTERVAL) return null;
    
    //add a new token
    KineticString ks = new KineticString(tokens[tokenIndex++]);
    ks.parent = id;
    ks.group = tokenLoop;
    ks.setPos(pos.x, pos.y, pos.z-10);
    ks.setFriction(1, 0.98f);
    ks.push(pushForce*cos(pushAngle),
            pushForce*sin(pushAngle),
            -5);
    ks.spin(rotVel*SPRAY_ANGULAR_FORCE);

    //loop back to the first token if need
    //adjust time so that there is an pause before it loops back
    if (tokenIndex >= tokens.length) {
      tokenIndex = 0;
      tokenLoop++;
      lastSpray = age + SPRAY_LOOP_INTERVAL;
    }
    //keep track of time
    else {
      lastSpray = age;
    }
    
    //return the sprayed string
    return ks;
  }
  
  //apply acceleration
  void applyAcceleration() {
    //add acceleration
    vel.x += acc.x;
    vel.y += acc.y;

    //reset acceleration
    acc.x = 0;
    acc.y = 0;
    
    //apply friction
    vel.mult(ATTENUATION);
    
    //calculate target rotation based on velocity
    targetRot = atan2(vel.y, vel.x) + forward;
    if (targetRot == rot) return;
    
    //rotate towards the target rotation
    if (targetRot < 0) targetRot += TWO_PI;
    else if (targetRot > TWO_PI) targetRot -= TWO_PI;
    
    //calculate angular distance
    float dRot = targetRot - rot;  //-2PI - 2PI
    float dir = dRot < 0 ? -1 : 1;
    if (dRot*dir > PI) { dRot += TWO_PI*-dir; dir *= -1; }
    
    //apply angular force
    rotVel += dir*PI/1024;
    
    //attenuate only for high angular velocity
    if (rotVel*(rotVel<0?-1:1) > 0.1)
      rotVel *= ANGULAR_ATTENUATION;
      
    //change rotation
    rot += rotVel;

    if(rot < 0) rot += TWO_PI;
    if(rot > TWO_PI) rot -= TWO_PI;
  }
  
  //apply velocity
  void applyVelocity() { pos.add(vel); }

  //apply current force
  void applyCurrent(PVector current, float multiplier) {
    noiseDetail(4, 0.4f);
    float angle = (noise( pos.x/1000f, pos.y/1000f, pos.z )*2-1)*PI/8 + atan2(current.y, current.x);    
    
    // Update the agent's position / rotation
    acc.x += multiplier * cos( angle ) * CURRENT_STRENGTH * speed;
    acc.y += multiplier * sin( angle ) * CURRENT_STRENGTH * speed;    
  }
  
  //apply scatter force
  void applyScatter(float multiplier) {
    noiseDetail(4, 0.4f);
    float angle = noise( pos.x/1000f, pos.y/1000f, pos.z - scatterOffset ) * TWO_PI + offsetAngle;
    
    // Update the agent's position / rotation
    acc.x += multiplier * cos( angle ) * SCATTER_STRENGTH * speed;
    acc.y += multiplier * sin( angle ) * SCATTER_STRENGTH * speed;
  }
  
  //check if beast is outside bounds
  boolean isOutside(Rectangle2D.Float bounds) {
    return !bounds.contains(pos.x, pos.y);
  }
  
  //draw
  void draw() {
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    rotate(rot + (PI-forward));
    
    screenPos.x = screenX(0, 0, 0);
    screenPos.y = screenY(0, 0, 0);
    
    noStroke();
    float fr, fg, fb, fa;

    if (dfrmText != null) {
      //draw glypsh
      TessData data;
      for(int i = 0; i < dfrmText.length; i++) {
        data = dfrmText[i];
  
        fr = red(data.fill);
        fg = green(data.fill);
        fb = blue(data.fill);
        fa = alpha(data.fill);
        
        if (camouflage != 0) {
          fr += (CAMOUFLAGE_RED-fr)*camouflage;
          fg += (CAMOUFLAGE_GREEN-fg)*camouflage;
          fb += (CAMOUFLAGE_BLUE-fb)*camouflage;
          fa += (CAMOUFLAGE_ALPHA-fa)*camouflage;
        }
          
        fill(fr, fg, fb, fa);          
      
        //go through contours
        for(int j = 0; j < data.types.length; j++) {
          g.beginShape(data.types[j]);
          //go through vertices
          for(int k = j==0?0:data.ends[j-1]; k < data.ends[j]; k++) {
            g.vertex(data.vertices[k][0], data.vertices[k][1], data.vertices[k][2]);
          }
          g.endShape();  
        }
      }
    }
    
    //draw center cross
    if (DEBUG) {
      noFill();
      stroke(0);
      strokeWeight(2);
      pushMatrix();
      translate(mouth.x, mouth.y, mouth.z);
      line(-5, 0, 5, 0);
      line(0, -5, 0, 5);
      popMatrix();
       
      float tailDist = tail.x-mouth.x;
      if (tailDist < 0) tailDist *= -1;
  
      float a;
      a = tailDist / TAIL_BEND_FACTOR;
      a *= a;
      a *= rotVel;
    
      float newdx = -tail.x;
      float newdy = -tail.y;
      float rtfX = newdx * cos(a) - newdy * sin(a);
      float rtfY = newdx * sin(a) + newdy * cos(a);
      newdx = rtfX + tail.x;
      newdy = rtfY + tail.y;      

      stroke(255, 30, 45);
      pushMatrix();
      translate(tail.x, tail.y, tail.z);
      line(-5, 0, 5, 0);
      line(0, -5, 0, 5);
      line(0, 0, newdx, newdy);
      popMatrix();
    }    

    popMatrix();
  }
  
  //draw shadow
  void drawShadow() {
    if (shadow == null) return;

    pushMatrix();
    translate(screenX(pos.x, pos.y, pos.z), screenY(pos.x, pos.y, pos.z), 0);
    rotate(rot + (PI-forward));
    scale(1, 0.8);
    imageMode(CENTER);
    tint(19, 66, 99, 255);
    image(shadow, 0, 0, 256+(pos.z-MAX_BEAST_Z)/1.5, 256+(pos.z-MAX_BEAST_Z)/2);
    noTint();
    popMatrix();
  }
  
  //get number of glyphs in a NextText group
  int getGlyphCount(TextObjectGroup root) {
    int count = 0;
    TextObjectGlyphIterator it = root.glyphIterator();
    while(it.hasNext()) {
      it.next();
      count++;
    }
    return count;
  }
  
  //tesselate group
  TessData[] tesselate(TextObjectGroup root) {
    //make space for tesselation data
    TessData[] data = new TessData[getGlyphCount(root)];
    
    //loop through glyphs and tesselate one by one
    TextObjectGlyphIterator it = root.glyphIterator();
    TextObjectGlyph glyph;
    PVector pos;
    int count = 0;
    while(it.hasNext()) {
      glyph = it.next();
      
      data[count++] = tesselate(glyph, glyph.getPositionAbsolute().x < radius ? TESS_DETAIL_MAX : TESS_DETAIL_MIN);
    }
    
    return data;
  }
  
  //tesselate a glyph
  TessData tesselate(TextObjectGlyph glyph, float tessDetail) {
    // six element array received from the Java2D path iterator
    float textPoints[] = new float[6];
  
    // get absolute outline
    // get the glyph's position
    PVector pos = glyph.getPositionAbsolute();
    Rectangle bounds = glyph.getBounds();
    float rot = glyph.getParent().getRotation().get();  //a bit of a hack
    GeneralPath outline = new GeneralPath(glyph.getOutline());
    outline.transform(AffineTransform.getTranslateInstance(pos.x, pos.y));
    outline.transform(AffineTransform.getRotateInstance(rot, bounds.getX(), bounds.getY()));
    PathIterator iter = outline.getPathIterator(null);
  
    glu.gluTessBeginPolygon(tess, null);
    // second param to gluTessVertex is for a user defined object that contains
    // additional info about this point, but that's not needed for anything
  
    float lastX = 0;
    float lastY = 0;
  
    // unfortunately the tesselator won't work properly unless a
    // new array of doubles is allocated for each point. that bites ass,
    // but also just reaffirms that in order to make things fast,
    // display lists will be the way to go.
    double vertex[];
  
    while (!iter.isDone()) {
        int type = iter.currentSegment(textPoints);
        switch (type) {
            case PathIterator.SEG_MOVETO:
                glu.gluTessBeginContour(tess);
  
                vertex = new double[] { textPoints[0], textPoints[1], 0 };
                
                glu.gluTessVertex(tess, vertex, 0, vertex);
                
                lastX = textPoints[0];
                lastY = textPoints[1];
                
                break;
  
            case PathIterator.SEG_QUADTO:   // 2 points
            	
            	for (int i = 1; i <= tessDetail; i++) {
            		float t = (float)(i/tessDetail);
  	                    vertex = new double[] {
  	                            g.bezierPoint(
  	                                    lastX, 
  	                                    lastX + ((textPoints[0]-lastX)*2/3), 
  	                                    textPoints[2] + ((textPoints[0]-textPoints[2])*2/3), 
  	                                    textPoints[2], 
  	                                    t
  	                            ),
  	                            g.bezierPoint(
  	                                    lastY, 
  	                                    lastY + ((textPoints[1]-lastY)*2/3),
  	                                    textPoints[3] + ((textPoints[1]-textPoints[3])*2/3), 
  	                                    textPoints[3], 
  	                                    t
  	                            ), 
  	                            0
  	                    };
  	                    
  	                    glu.gluTessVertex(tess, vertex, 0, vertex);
            	}
                
                lastX = textPoints[2];
                lastY = textPoints[3];
                
                break;
  
            case PathIterator.SEG_CLOSE:
                glu.gluTessEndContour(tess);
                
                break;
        }
        
        iter.next();
    }
    
    glu.gluTessEndPolygon(tess);  
    
    // get the glyph's position
    //PVector pos = glyph.getPositionAbsolute();
    //float rot = glyph.getParent().getRotation().get();  //a bit of a hack

    TessData data = tessCallback.getData();
    //data.translate(pos);
    //data.rotate(rot);
    data.stroke = ColorTocolor(glyph.getStrokeColor().get());
    data.fill = ColorTocolor(glyph.getColor().get());
    return data;
  }
}
