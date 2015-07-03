/*
 * Copyright 2011 Obx Labs / Jason Lewis
 * Developed by Bruno Nadeau
 
 Copyright (C) <2015>  <Jason Lewis>
  
    This program is free software: you can redistribute it and/or modify
    it under the terms of the BSD 3 clause with added Attribution clause license.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   BSD 3 clause with added Attribution clause License for more details.
 */

import processing.opengl.*;
import fullscreen.*;

import java.awt.Color;
import java.awt.geom.PathIterator;
import java.awt.geom.GeneralPath;
import java.awt.geom.AffineTransform;
import java.awt.geom.Rectangle2D;
import java.awt.Rectangle;

import java.util.Arrays;

import PQSDKMultiTouch.*;
import javax.swing.JOptionPane;

import javax.media.opengl.GL;
import javax.media.opengl.glu.GLU;
import javax.media.opengl.glu.GLUtessellator;
import javax.media.opengl.glu.GLUtessellatorCallbackAdapter;

import net.nexttext.*;
import net.nexttext.behaviour.standard.*;
import net.nexttext.behaviour.control.*;
import net.nexttext.behaviour.dform.*;
import net.nexttext.behaviour.physics.*;
import net.nexttext.behaviour.*;
import net.nexttext.input.*;
import net.nexttext.renderer.*;
import net.nexttext.property.*;

import processing.video.*;

boolean FULLSCREEN = true;            //true to start in fullscreen mode, false for window
boolean DEBUG = false;                 //true to turn on debug mode (display extra info)
boolean FRAMERATE = false;              //true to show framerate
boolean SHADOWS = true;                //true to draw beast shadows
boolean PQLABS_TOUCHSCREEN = true;    //true when using PQLabs touchscreen
boolean CURSOR = !PQLABS_TOUCHSCREEN;  //false to hide cursor

final int FPS = 30;                                //target frames per second
final int BG_COLOR = 50 << 24 |                    //background color
                     31 << 16 |                      //red
                     147 << 8 |                      //green
                     191;                            //blue
final String TEXT_FILE = "TheGreatMigration.txt";  //text file
final String FONT_FILE = "olvr93w.ttf";            //font file
final int FONT_SIZE = 36;                          //font size
final int WORD_SPACING = 20;                       //pixels between each word
final String PAGE = "PAGE";                        //NextText book page name

final float BEAST_ANGLE_SPREAD = PI/6;             //defines the miximum arc of a beasts tail
final float BEAST_X_OFFSET = -25;                  //offset the text in the beast to adjust the lens effect
final int BEAST_LENGTH = 4;                        //number of words for each tail piece
final int BEAST_RADIUS = 200;                      //radius of the beasts' lens effect
final int BEAST_TARGET_RADIUS = 225;               //radius of the beasts' lens effect when touched
final int MIN_BEAST_Z = -400;                      //minimum z pos of a beast
final int MAX_BEAST_Z = -1000;                     //maximum z position of a beast
final int SPAWNING_BORDER = 500;                   //width of the border where the beasts spawn
final int NOISE_MIN_BEASTS = 1;                    //minimum number of beasts for noise calculation
final int NOISE_MAX_BEASTS = 15;                   //maximum number of beasts for noise calculation
final float NOISE_PERIOD_BEASTS = 500f;            //period noise calculation (bigger the number, the slower the change in maximum beasts)
final int MAX_BEASTS = 12;                         //maximum number of beasts
final int READ_DISTANCE = 120;                     //radius that defines the hotspot to touch and grab a beast
final float CURRENT_DIRECTION = -PI + PI/12;       //direction of the current

final float SPRAY_LIFETIME = 10000;                //milliseconds a sprayed word stays on screen
final float SPRAY_FADE_PERIOD = 3000;              //milliseconds it takes for a sprayed word to fade in/out
final int SPRAY_COLOR = 255 << 24 |                //color of sprayed words, alpha
                        255 << 16 |                  //red
                        255 << 8 |                   //green
                        255;                         //blue
final int SPRAY_OPACITY = 90;                      //opacity of sprayed words
final int SPRAY_WORDS_ON_TOUCH = 3;                //words to spray on first touch
final int SPRAY_WORDS_ON_TOUCH_FORCE = 2;          //force with which the first sprayed word are pushed
final int SPRAY_CONNECTION_TIME = 1000;            //milliseconds from birth until a connection is drawn
final int SPRAY_HIGHLIGHT_COLOR = 150 << 24 |      //color of sprayed words, alpha
                                  245 << 16 |        //red
                                  216 << 8 |         //green
                                  143;               //blue
final float SPRAY_HIGHLIGHT_START = 4000;          //when the spray circle highlight should start fading in
final float SPRAY_HIGHLIGHT_PERIOD = 2000;         //how long in millis it takes to fade in or out
final float TOUCH_PUSH_RADIUS = 250;               //maximum radius effect of touch push
final float TOUCH_PUSH_FORCE = 1f;                 //force multiplier to touch push

final long TOUCH_PARTICLE_LIFE = 1500;             //life in millis of the touch particles
final float TOUCH_PARTICLE_SCALE = 2;               //initial scale of touch particles
final int TOUCH_PARTICLE_COLOR = 20 << 24 | 255 << 16 | 255 << 8 | 255; //color of touch particles
final float TOUCH_PARTICLE_SPIN = 0.1;              //touch particle spin
final float TOUCH_PARTICLE_PUSH = 1.5;              //force of touch particle push

//OpenGL
PGraphicsOpenGL pgl;
GL gl;
GLU glu;
TessCallback tessCallback;  //tesselator's callback
GLUtessellator tess;        //tesselator
float fov, cameraZ;         //field of view and camera's z position
Rectangle2D.Float bounds;   //bounds of far plane (to calculate of objects are outside)

//Background
PerlinTexture bgImage;      //the background dynamic texture

//fullscreen manager
SoftFullScreen sfs;         //fullscreen util

//text properties
Book book;                  //NextText book
TextPage page;              //book's page
PFont font;                 //the font
String[] textStrings;       //loaded text strings
int stringIndex;            //index of the next string

long lastUpdate = 0;        //last time the sketch was updated
long now = 0;               //current time
long dt;                    //time difference between draw calls

Beast[] beasts;             //the beasts
int totalBeastCount;        //total number of created beast up to now
int currentBeastCount;      //current number of beasts on screen
PImage shadow;              //the generic shadow image
PVector current;            //current (flow) direction
float scatter;              //scatter factor (0 = no scatter, 1 = all scatter)
HashMap readBeasts = new HashMap();
LinkedList sprayTokens;     //list of sprayed tokens
AgingLinkedList touchParticles; //particle released under touches

//touchscreen
HashMap touches = new HashMap();
TouchClient touchClient = null;              //pqlabs touchscreen client
MigrationTouchDelegate touchDelegate = null; //touch delegate

//output
MovieMaker mm = null;       //movie maker for video output
boolean mmOutput = false;   //true to output, false doesn't
int mmCount = 0;            //count of recorded videos

void setup() {
  //if we are an applet
  if (online)
    size(900, 600, OPENGL);
  //set size to match PQLabs touchscreen if active
  else if (PQLABS_TOUCHSCREEN && FULLSCREEN)
    size(1920, 1080, OPENGL);
  //or use generic size
  else if (FULLSCREEN)
    size(screenWidth, screenHeight, OPENGL);
  else
    size(1280, 720, OPENGL);
    
  hint(ENABLE_OPENGL_4X_SMOOTH);    //4x anti-aliasing (although does not seem to do much)
  frameRate(FPS);                   //set framerate

  //set perspective
  fov = PI/3.0;
  cameraZ = ((height/2.0) / tan(PI*60.0/360.0));
  perspective(fov, (float)width/(float)height, cameraZ/10.0, cameraZ*10.0);

  //calculate bounds (to check if beasts are outside)
  int minY = -int(tan(fov/2) * -MAX_BEAST_Z) - SPAWNING_BORDER;
  int minX = minY * width/height;
  int w = -2*minX + width;
  int h = -2*minY + height;
  bounds = new Rectangle2D.Float(minX, minY, w, h);
  
  //init tesselator
  glu = new GLU();
  tess = glu.gluNewTess();
  tessCallback = new TessCallback();
  glu.gluTessCallback(tess, GLU.GLU_TESS_BEGIN, tessCallback); 
  glu.gluTessCallback(tess, GLU.GLU_TESS_END, tessCallback); 
  glu.gluTessCallback(tess, GLU.GLU_TESS_VERTEX, tessCallback); 
  glu.gluTessCallback(tess, GLU.GLU_TESS_COMBINE, tessCallback); 
  glu.gluTessCallback(tess, GLU.GLU_TESS_ERROR, tessCallback); 

  //create the fullscreen object
  if (FULLSCREEN) {  
    //create the soft fullscreen
    sfs = new SoftFullScreen(this, 0);
    sfs.enter(); 
  }
  
  //remove the cursor
  if (!CURSOR) noCursor();
      
  //create background texture
  bgImage = new PerlinTexture();
      
  //init NextText
  book = new Book(this);
  page = book.addPage(PAGE);

  //load font
  font = createFont(FONT_FILE, FONT_SIZE, true);

  //set the current direction
  current = new PVector(cos(CURRENT_DIRECTION), sin(CURRENT_DIRECTION));
  scatter = 0; //no scatter to start
  
  //load the text file
  loadText(TEXT_FILE);
  
  //load shadow image
  shadow = loadImage("shadow.png");
  
  //make space for the sprayed words
  sprayTokens = new LinkedList();
  
  //make space for the touch particles
  touchParticles = new AgingLinkedList(TOUCH_PARTICLE_LIFE);
  
  //init beast counters
  totalBeastCount = 0;
  currentBeastCount = 0;
  
  //keep track of time
  now = millis();
  lastUpdate = now;
  
  //init pqlabs touchscreen
  if (PQLABS_TOUCHSCREEN) {
    touchDelegate = new MigrationTouchDelegate(this);
    touchClient = new TouchClient();
    touchClient.setDelegate(touchDelegate);
  }  
}

void draw() {
  //millis since last draw
  dt = now-lastUpdate;
  
  //draw background texture
  bgImage.update(dt);
  bgImage.draw(0, 0, width, height);
  noStroke();
  fill(BG_COLOR);
  rect(0, 0, width, height);

  //update the touch particles
  updateTouchParticles(dt);

  //update the sprayed words  
  updateSpray(dt);
  
  //update the beasts
  updateBeasts(dt);
  
  //draw shadows
  if (SHADOWS) drawShadows();

  //draw touch particles
  drawTouchParticles();

  //clear depth buffer
  //to start drawing over background
  hint(DISABLE_DEPTH_TEST);
  hint(ENABLE_DEPTH_TEST);

  //draw the sprayed words
  drawSpray();

  //clear depth buffer
  //to start drawing over background
  hint(DISABLE_DEPTH_TEST);
  hint(ENABLE_DEPTH_TEST);

  //draw the beasts
  drawBeasts();
  
  //draw the framerate
  if (FRAMERATE) drawFrameRate();
  
  //keep track of time
  lastUpdate = now;
  now = millis();

  //output
  if (mmOutput) mm.addFrame();  //add window's pixels to movie 
}

//draw the framerate
void drawFrameRate() {
  noStroke();
  fill(0, 255, 0);
  textFont(font, 12);
  textAlign(LEFT, BASELINE);
  text(frameRate, 5, 15);
}

//update the beasts
void updateBeasts(long dt) {
  //limit the max beast to one more than current
  int maxBeasts = min(maxBeasts(), currentBeastCount+1);
  
  //go through beasts
  for(int i = 0; i < beasts.length; i++) {  
    //if we are parsing the dragged beast
    if (isReadingBeast(beasts[i])) {
      //decrease beast camouflage (aka the highlight)
      beasts[i].incCamouflage();
      
      //approach it towards the touch
      PVector touch = getTouchForBeast(beasts[i]);
      if (touch != null)
        beasts[i].approach(touch.x, touch.y);
      else
        System.err.println("Warning: We got a null touch for a beast.");  
        
      //spray words from it
      synchronized(sprayTokens) {
        KineticString ks = beasts[i].spray();
        if (ks != null) sprayTokens.add(ks);
      }
    }
    //if any other beast
    else {
      //create a new beast if we are missing one
      if (beasts[i] == null)
        //if the current beast count is less than the
        //dynamic maximum beast amount, the create one
        if (currentBeastCount < maxBeasts)
          beasts[i] = createBeast();
        else
          continue;
      //if the beast is outside the view then remove it
      else if (beasts[i].isOutside(bounds)) {
        removeBeast(i);
        continue;
      }
        
      //decrease beast camouflage
      beasts[i].decCamouflage();

      //make it swim around
      beasts[i].swim();
    }    

    //update the beast    
    beasts[i].update(dt);
  }
  
  //attenuate scatter for new beasts
  if (scatter > 0) {
    scatter -= 0.25f / dt;
    if (scatter < 0) scatter = 0;
  }  
}

//maximum number of beasts at a given time
int maxBeasts() {
  noiseDetail(4, 0.4f);
  return min(MAX_BEASTS, (int)(NOISE_MIN_BEASTS + noise(frameCount/NOISE_PERIOD_BEASTS)*(NOISE_MAX_BEASTS-NOISE_MIN_BEASTS)));
}

//update touch particles
void updateTouchParticles(long dt) {
  //update particles
  touchParticles.update(dt);
   
  //add new ones for each touch
  Iterator it = null;
  synchronized(touches) {
    it = touches.keySet().iterator();
  
    //loop through touches
    Beast b;
    Integer iid;
    PVector v;
    while(it.hasNext()) {
      //get next touch id
      iid = ((Integer)it.next()).intValue();
      
      //get touch location for this id
      //synchronized(touches) {
        v = (PVector)touches.get(iid);
      //}
      
      //get the matching beast, if any
      b = (Beast)readBeasts.get(iid);
  
      //if we have a beast, and the touch is close to it, then don't make particles
      if (b != null && b.distToPoint(v.x, v.y) <= 0) continue;
      
      //create a new particle
      //TouchParticle tp = getTouchParticle();
      TouchParticle tp = (TouchParticle)touchParticles.recycle();
      if (tp == null) tp = new TouchParticle();
      tp.setPos(v.x, v.y, 0);
      tp.setFriction(1, 0.98f);
      tp.setFadeRate(alpha(TOUCH_PARTICLE_COLOR)/(float)TOUCH_PARTICLE_LIFE);
      tp.push(TOUCH_PARTICLE_PUSH*cos(random(TWO_PI)), TOUCH_PARTICLE_PUSH*sin(random(TWO_PI)), -10);
      tp.spin(TOUCH_PARTICLE_SPIN);
      tp.setColor(TOUCH_PARTICLE_COLOR);
      tp.setScale(random(0.5, 2)*TOUCH_PARTICLE_SCALE);
      touchParticles.add(tp);
    }
  }
}

//update sprayed words
void updateSpray(long dt) {
  //update sprayed tokens
  synchronized(sprayTokens) {
    KineticString ks;
    ListIterator it = sprayTokens.listIterator();
    while(it.hasNext()) {
      //get it
      ks = (KineticString)it.next();
      
      //update it
      ks.update(dt);
      
      //if the sprayed word is too old, remove it
      if (ks.age() > SPRAY_LIFETIME)
        it.remove();
    }  
  }
}

//scatter the beasts
void scatterBeasts() {
  //loop through beasts and set scatter factor
  for(int i = 0; i < beasts.length; i++) {
    if (beasts[i] != null) beasts[i].scatter();
  }
}

//try to 'read' the beast under the given x,y position
void readBeast(int id, int x, int y) {
  PVector screenPos;
  float dx, dy, d;
  
  //find the closest beast under the point
  int closestBeast = -1;
  float closestDist = READ_DISTANCE;
  for(int i = 0; i < beasts.length; i++) {
    //if the beast slot is empty, pass
    if (beasts[i] == null) continue;
    
    //get the distance to the beasty
    screenPos = beasts[i].getScreenPos();
    dx = screenPos.x - x;
    dy = screenPos.y - y;
    d = sqrt(dx*dx + dy*dy);
    
    //check if we are close enough and closer than last
    if (d < closestDist) {
      closestBeast = i;
      closestDist = d;
    }
    else {
      beasts[i].acc.x += dx/d * TOUCH_PUSH_RADIUS/d * TOUCH_PUSH_FORCE;
      beasts[i].acc.y += dy/d * TOUCH_PUSH_RADIUS/d * TOUCH_PUSH_FORCE;
    }
  }
  
  //if we found one
  if (closestBeast != -1) {
    //set the dragged beast
    readBeasts.put(new Integer(id), beasts[closestBeast]);
    //increase the lens effect
    beasts[closestBeast].setTargetRadius(BEAST_TARGET_RADIUS);
  }
  //if not make sure there's no left over
  else {
    readBeasts.remove(new Integer(id));
  }
}

//check if a beast is being read for a certain touch id
boolean isReadingBeastForId(int id) { 
  return (readBeasts.get(id) != null);
}

//check if a beast is being read/dragged
boolean isReadingBeast(Beast b) {
  return readBeasts.containsValue(b);
}

//get the touch for the matching beast, if any
PVector getTouchForBeast(Beast b) {
  Iterator it = readBeasts.keySet().iterator();
  while(it.hasNext()) {
    Integer id = (Integer)it.next();
    if (b == (Beast)readBeasts.get(id)) {
      PVector v = null;
      synchronized(touches) {
        v = (PVector)touches.get(id);
      }
      return v;
    }
  }
  return null;
}

//draw the beasts' shadows
void drawShadows() {
  pgl = (PGraphicsOpenGL) g;
  gl = pgl.beginGL();
  gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_LINEAR);
  gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_LINEAR);
  pgl.endGL();
  
  for(int i = 0; i < beasts.length; i++) {
    if (beasts[i] == null) continue;
    beasts[i].drawShadow();
  }
}

//draw the beasts
void drawBeasts() {
  //draw the actual beasts
  for(int i = 0; i < beasts.length; i++) {
    if (beasts[i] == null) continue;
    beasts[i].draw();
  }
  
  //draw some debug info
  if (DEBUG) {
    for(int i = 0; i < beasts.length; i++) {
      if (beasts[i] == null) continue;
      noFill();
      stroke(0, 50);
      strokeWeight(2);
      pushMatrix();
      translate(screenX(beasts[i].pos.x, beasts[i].pos.y, beasts[i].pos.z),
                screenY(beasts[i].pos.x, beasts[i].pos.y, beasts[i].pos.z),
                0);
      ellipse(0, 0, READ_DISTANCE*2, READ_DISTANCE*2);
      popMatrix();
    }
  }
}

//draw touch particles
void drawTouchParticles() {
  ListIterator it = touchParticles.listIterator();
  TouchParticle tp;
  while(it.hasNext()) {
    tp = (TouchParticle)it.next();
    tp.draw();
  }
}

//draw sprayed tokens
void drawSpray() {
  synchronized(sprayTokens) {
    KineticString ks;
    ListIterator it = sprayTokens.listIterator();
    KineticString lastks = null;
    float lastWidth = 0;
    float opacity;
  
    while(it.hasNext()) {
      ks = (KineticString)it.next();
  
      textFont(font, FONT_SIZE);
      textAlign(CENTER, CENTER);
      float tWidth = textWidth(ks.string) + 20;
  
      //calculate ease in/out factor
      if (ks.age() < SPRAY_FADE_PERIOD)
        opacity = ks.age() / SPRAY_FADE_PERIOD;
      else if (ks.age() > SPRAY_LIFETIME - SPRAY_FADE_PERIOD)
        opacity = (ks.age() - SPRAY_LIFETIME) / SPRAY_FADE_PERIOD * -1;
      else
        opacity = 1;
      
      //easy in/out
      opacity = (opacity - sin(opacity*TWO_PI) / TWO_PI)* SPRAY_OPACITY;
    
      //text
      pushMatrix();
      translate(ks.pos.x, ks.pos.y, ks.pos.z);
      rotate(ks.ang);
      noStroke();
      fill(SPRAY_COLOR, opacity);
      text(ks.string, 0, 0);
      popMatrix();
      
      //keep track of last token to draw connections
      lastks = ks;
      lastWidth = tWidth;
    }  
  }
}

//load text
void loadText(String textFile) {
  //load text file
  print("Loading text file '" + textFile + "'... ");
  textStrings = loadStrings(textFile);

  print("Done (" + textStrings.length + " line");
  if (textStrings.length > 1) print("s");
  println(")");

  //start at first string
  stringIndex = 0;

  //make space for the beasties
  beasts = new Beast[MAX_BEASTS];
}

//remove beast at a given index
void removeBeast(int i) {
  beasts[i] = null;
  currentBeastCount--;
}

//create a beast
Beast createBeast() {
  //set default properties
  Beast beast = new Beast(getBeastStartPosition());
  beast.id = totalBeastCount;
  beast.setMagnification(0.85, random(0, TWO_PI));
  beast.setRadius(BEAST_RADIUS);
  beast.setSpeed(random(0.5f, 4f));
  beast.setScatter(scatter);
  beast.shadow = shadow;
  beast.setForward(current.x > 0 ? PI : 0);

  //add text to the book 
  textAlign(LEFT, CENTER);
  textFont(font, FONT_SIZE);
    
  //add the line to the page
  fill(0);
  noStroke();
  TextObjectGroup grp = book.addText(textStrings[stringIndex], 0, 0, PAGE);
  TextObject child;    

  //set the beast's text string
  beast.setText(page.getTextRoot().toString());

  //remove spaces
  child = grp.getLeftMostChild();
  while(child != null) {
    TextObject tmpChild = child;
    child = child.getRightSibling();
    if (tmpChild.toString().equals(" ")) tmpChild.detach();
  }

  //place the text into the beasty's shape
  child = grp.getLeftMostChild();
  int numChild = grp.getNumChildren();
  int cChild = 0;
  float nextRot = random(-BEAST_ANGLE_SPREAD, BEAST_ANGLE_SPREAD);
  float tailLength = 0;
  while(child != null) {
    //set position
    PVector pos = child.getPosition().get();
    pos.x = cos(nextRot)*tailLength + BEAST_X_OFFSET;
    pos.y += sin(nextRot) * tailLength;
    child.getPosition().set(pos);
    
    //set rotation
    child.getRotation().set(nextRot);
    
    //set color
    if (child instanceof TextObjectGroup) {
      TextObjectGlyphIterator it = ((TextObjectGroup)child).glyphIterator();
      Color clr = colorToColor(color(random(200, 255), random(10, 50)));
      while(it.hasNext()) {
        it.next().getColor().set(clr);
      }
    }

    //count children
    cChild++;      
    
    //reset at the end of each tail section
    if (cChild%BEAST_LENGTH == 0) {
      nextRot = random(-BEAST_ANGLE_SPREAD, BEAST_ANGLE_SPREAD);
      tailLength = 0;
    }
    //or keep track of tail length
    else {
      tailLength += child.getBounds().width + WORD_SPACING;
    }
   
    //next
    child = child.getRightSibling();
  }
    
  //set the beast-shaped text of the beast
  beast.setOriginalText(page.getTextRoot());

  //clear the book (we only use it to easy position text)
  book.clear();
  book.step();

  //track which string we are at from the text
  stringIndex++;
  if (stringIndex >= textStrings.length) stringIndex = 0;

  //keep count
  totalBeastCount++;
  currentBeastCount++;

  //return the beasty
  return beast;
}

//get a random start position for a beast
PVector getBeastStartPosition() { return getBeastStartPosition(MIN_BEAST_Z + random(MAX_BEAST_Z-MIN_BEAST_Z)); }
PVector getBeastStartPosition(float z) {
  int maxY = int(tan(fov/2) * -z);
  int maxX = maxY * width/height;
  int w = 2*maxX + width;
  int h = 2*maxY + height;

  //find a point based on the current direction
  float angle = atan2(current.y, current.x) + PI + random(-PI/8, PI/8);
  float x = width/2 + cos(angle) * (w/2 + SPAWNING_BORDER);
  float y = height/2 + sin(angle) * (w/2 + SPAWNING_BORDER);
  
  return new PVector(x, y, z);
}

//keyboard
void keyPressed() {
  switch(key) {
    //start/stop recording video
    case ENTER:
      if (!mmOutput) {
        println("Start recording...");
        mmCount++;
        mm = new MovieMaker(this, width, height, "TheGreatMigration_"+mmCount+".mov",
                            FPS, MovieMaker.ANIMATION, MovieMaker.LOSSLESS);
        mmOutput = true;
      } else {
        println("End recording.");
        mm.finish();
        mmOutput = false;
      }
      break;
    //save frame
    case 's':
      println("Save frame " + frameCount);
      saveFrame("TheGreatMigration_" + frameCount + ".png");
      break;
  }
}

//mouse pressed
void mousePressed() {
  if (PQLABS_TOUCHSCREEN) return;
  mousePressed(1, mouseX, mouseY); 
}

void mousePressed(int id, int x, int y) {
  if (isReadingBeastForId(id)) return;

  //keep track of touch
  Integer iid = new Integer(id);
  PVector pos = new PVector(x, y, 0);  
  synchronized(touches) {
    touches.put(iid, pos);
  }
  
  scatterBeasts();           //scatter beasts
  scatter = 1.0;             //up the scatter factor for newly created beasts
  readBeast(id, x, y); //check if we are close enough to a beast to drag
}

//mouse dragged
void mouseDragged() {
  if (PQLABS_TOUCHSCREEN) return;
  mouseDragged(1, mouseX, mouseY);
}

void mouseDragged(int id, int x, int y) {
  //update position to keep track of touch
  PVector v = null;
  Integer iid = new Integer(id);
  
  synchronized(touches) {
    v = (PVector)touches.get(iid);
  }
  
  if (v != null) v.set(x, y, 0);
  
  //do the same as when pressed
  mousePressed(id, x, y);
}

//mouse released
void mouseReleased() {
  if (PQLABS_TOUCHSCREEN) return;
  mouseReleased(1, mouseX, mouseY);
}

void mouseReleased(int id, int x, int y) {
  //clear touch
  Integer iid = new Integer(id);
  synchronized(touches) {   
    touches.remove(iid);
  }
  
  if (!isReadingBeastForId(id)) return;
  
  //if we were dragging a beasty, then scare it away and release it
  Beast beast = (Beast)readBeasts.get(iid);
  beast.scatter();
  beast.setTargetRadius(BEAST_RADIUS);
  
  for(int i = beast.tokenLoop*beast.tokens.length + beast.tokenIndex;
      i < SPRAY_WORDS_ON_TOUCH;
      i++) {
    //spray words from it
    KineticString ks = beast.spray(TWO_PI/FPS*frameCount + TWO_PI/SPRAY_WORDS_ON_TOUCH*i, SPRAY_WORDS_ON_TOUCH_FORCE, true);
    if (ks != null) {
      //need to rewind age to control the highlight (this should be done better)
      ks.age -= i*Beast.SPRAY_INTERVAL;
      
      synchronized(sprayTokens) {
        sprayTokens.add(ks);
      } 
    }
  }

  //clear beast
  readBeasts.remove(iid);
}

//convert color to Color
Color colorToColor(color c) { return new Color(int(red(c)), int(green(c)), int(blue(c)), int(alpha(c))); }

//convert Color to color
color ColorTocolor(Color c) { return color(c.getRed(), c.getGreen(), c.getBlue(), c.getAlpha()); }
