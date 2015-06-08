/*
 * Copyright 2010 Obx Labs Jason Lewis
 */
 
import net.nexttext.*;
import net.nexttext.behaviour.standard.*;
import net.nexttext.behaviour.control.*;
import net.nexttext.behaviour.physics.*;
import net.nexttext.behaviour.*;
import net.nexttext.input.*;
import net.nexttext.renderer.*;
import net.nexttext.property.*;

import processing.video.*;

import PQSDKMultiTouch.*;
import javax.swing.JOptionPane;

import fullscreen.*; 
import processing.opengl.*;
import javax.media.opengl.*;
import java.nio.FloatBuffer;
import java.awt.Rectangle;
import java.awt.Color;
import java.awt.event.InputEvent;
import java.awt.event.MouseEvent;

/**
 * The Things You've Said...
 * by Jason Lewis
 * development by Bruno Nadeau
 */

//constants 
final int FPS = 30;
final boolean FULLSCREEN = true;
boolean PQLABS_TOUCHSCREEN = true;    //true when using PQLabs touchscreen
boolean CURSOR = !PQLABS_TOUCHSCREEN;  //false to hide cursor

final String[] TEXT_FILES = {"center.txt"};
final String[] PAGES = {"center", "focus", "unfocus", "prompt"};
final String CENTER_PAGE = PAGES[0];
final String FOCUS_PAGE = PAGES[1];
final String UNFOCUS_PAGE = PAGES[2];
final String PROMPT_PAGE = PAGES[3];
final PVector FOCUS_PAGE_POSITION = new PVector(0, 0, -200);
final String FONT_FILE = "olvr93w.ttf";
final float FONT_SIZE_RATIO = 5.68;
final ArrayList[] TEXTS = new ArrayList[TEXT_FILES.length];
final int[] BG_OFFSET = {50, 0, 0, 0};
final float PAGE_FORWARD_SPEED = 8;
final float PAGE_BACKWARD_SPEED = 20;

final float FADE_IN_SPEED = 14;
final float FADE_OUT_SPEED = 25;
final float FADE_IN_BG_SPEED = 8;
final float FADE_OUT_BG_SPEED = 25;

final boolean FOG = true;
final long STROKE_FADE_INTERVAL = 5*60*1000 / 255; //5min / 255
final long UNFOCUS_TIMER_INTERVAL = 2*60*1000;
final long PROMPT_TIMER_INTERVAL = 5*60*1000;
final long FIRST_AUTOPLAY_TIMER_INTERVAL = UNFOCUS_TIMER_INTERVAL + 2*60*1000;
final long AUTOPLAY_TIMER_INTERVAL = 10*1000;
final long AUTOPLAY_RELEASE_TIMER = 1000;

//fullscreen manager
SoftFullScreen sfs;

//graphics
color bgClr = color(0);  //background color
color fogClr = color(255);  //fog color
color textBgFillClr = color(255, 255, 255, 255);          //fill color of the text in the background
color textBgStrokeClr = color(0, 0, 0, 255);          //stroke color of the text in the background
color textNoFogBgStrokeClr = color(0, 0, 0, 70);
color textFgFillClr = color(102, 0, 145, 255);  //fill color of the text in the foreground (102,0,145) 
color textFgStrokeClr = color(0, 0, 0, 0);       //stroke color of the text in the foreground

color sameTextBgFillClr = color(255, 255, 255, 255);      //fill color of the sibling text in the background
color sameTextBgStrokeClr = color(0, 0, 0, 0);      //stroke color of the sibling text in the background
color sameTextFgFillClr = color(75, 15, 105, 255);  //fill color of the sibling text in the foreground
color sameTextFgStrokeClr = color(0, 0, 0, 50);      //stroke color of the sibling text in the foreground

color promptFillClr = color(240, 182, 46, 255); //fill color of the prompt

Book book;
TTYSTextPageRenderer renderer;
PFont font24pt;
PFont font;
float fontSize;

//behaviours
//Chain focusChain;
Multiplexer focusMulti;
Chain sameChain;
Chain unfocusChain;
Multiplexer unfocusMulti;
Chain unfocusColorChain;
Chain unfocusSameColorChain;
OnFocusLine slowFadeOnFocusLine;
OnFocusLine wanderOnFocusLine;
OnFocusLine unfocusSameOnFocusLine;
OnFocusLine unfocusOnFocusLine;

//fog
PGraphicsOpenGL pgl;
GL gl; 

//focus
long lastFocus = -PROMPT_TIMER_INTERVAL;
boolean mouseWasPressed = false;
PVector mouseWasPressedPt = new PVector();

//autoplay
boolean autoplay;
long lastAutoplay = 0;
ArrayList autoplayObjs = new ArrayList();
int autoplayLine = 0;

//visibility flags
boolean showFrameRate = false;

//Video output
MovieMaker mm;
boolean mmOutput = false;

//touchscreen
TouchClient touchClient = null;              //pqlabs touchscreen client
BuzzTouchDelegate touchDelegate = null;      //touch delegate

void setup() {
  //set size to match PQLabs touchscreen if active
  if (PQLABS_TOUCHSCREEN && FULLSCREEN)
    size(1920, 1080, OPENGL);
  //or use generic size
  else
    //size(1366, 768, OPENGL);
    size(1680, 1050, OPENGL);
  
  
  
  smooth();
  frameRate(FPS);

  //init fog
  pgl = (PGraphicsOpenGL)g;
  gl = pgl.gl; 

  if (FOG) {
    float[] fogColor= { red(fogClr)/255.0f, green(fogClr)/255.0f, blue(fogClr)/255.0f, 1.0f };
    gl.glClearColor(0.0f, 0.0f, 0.0f, 0.5f);    // Black Background
    gl.glClearDepth(1.0f);                      // Depth Buffer Setup
    gl.glEnable(GL.GL_DEPTH_TEST);              // Enables Depth Testing
    gl.glDepthFunc(GL.GL_LEQUAL);               // The Type Of Depth Testing To Do
    gl.glHint(GL.GL_PERSPECTIVE_CORRECTION_HINT, GL.GL_NICEST);	// Really Nice Perspective Calculations
    gl.glEnable(GL.GL_TEXTURE_2D);
    gl.glClearColor( 0.5f, 0.5f, 0.5f, 1.0f);
    gl.glFogi(GL.GL_FOG_MODE, GL.GL_LINEAR);
    gl.glFogf(GL.GL_FOG_DENSITY, 0.35f);
    gl.glHint(GL.GL_FOG_HINT, GL.GL_NICEST);
    gl.glFogfv(GL.GL_FOG_COLOR, FloatBuffer.wrap(fogColor,0,fogColor.length));
    gl.glFogf(GL.GL_FOG_START, 0);
    gl.glFogf(GL.GL_FOG_END, height*2);
    gl.glDisable(GL.GL_FOG);
  }
  
  // Create the fullscreen object
  if (FULLSCREEN) {  
    //create the soft fullscreen
    sfs = new SoftFullScreen(this, 0);
    
    // enter fullscreen mode
    sfs.enter(); 
  }
  
  //remove the cursor
  if (!CURSOR) noCursor();
    
  //load the text files
  loadTexts();

  // NextText
  book = new Book(this);
  renderer = new TTYSTextPageRenderer(this);
  for(int i = 0; i < PAGES.length; i++)
    book.addPage(PAGES[i]);
  
  //move the center backwards
  book.getPage(CENTER_PAGE).getPosition().set(new PVector(0, 0, -200));
  book.getPage(FOCUS_PAGE).getPosition().set(new PVector(0, 0, -200));
  book.getPage(UNFOCUS_PAGE).getPosition().set(new PVector(0, 0, 0));
  book.getPage(PROMPT_PAGE).getPosition().set(new PVector(0, 0, 0));
 
  //load fonts
  fontSize = (int)(height/FONT_SIZE_RATIO);
  font = createFont(FONT_FILE, fontSize, true);
  //font = loadFont("AntiqueOliveCompact-Regular-135.vlw");
  font24pt = createFont(FONT_FILE, 24, true);
  
  //add the texts to the book
  addCenterText();
  addPromptText();

  //init pqlabs touchscreen
  if (PQLABS_TOUCHSCREEN) {
    touchDelegate = new BuzzTouchDelegate(this);
    touchClient = new TouchClient();
    touchClient.setDelegate(touchDelegate);
  }  
}

void draw() {
  //fog
  if (FOG && FULLSCREEN) {
    float[] fogColor= { red(fogClr)/255.0f, green(fogClr)/255.0f, blue(fogClr)/255.0f, 1.0f };
    gl.glFogfv(GL.GL_FOG_COLOR, FloatBuffer.wrap(fogColor,0,fogColor.length));
    gl.glFogi(GL.GL_FOG_MODE, GL.GL_LINEAR);
    gl.glFogf(GL.GL_FOG_START, 0);
    gl.glFogf(GL.GL_FOG_END, height*2);
    gl.glDisable(GL.GL_FOG);
  }
    
  //gl.glDisable(GL.GL_DEPTH_TEST);
  
    //clear
  background(bgClr);
    
  //draw the texts
  book.step();
  drawBook();

  if (mmOutput)
    mm.addFrame();  // Add window's pixels to movie 

  if (mouseWasPressed) {
    //println("mouse was pressed: " + frameCount);
    
    //stop autoplay
    autoplay = false;
    
    //get the top word
    TextPage centerPage = book.getPage(CENTER_PAGE);
    TextObject to = getTopWord(centerPage.getTextRoot(), (int)mouseWasPressedPt.x, (int)mouseWasPressedPt.y, (int)centerPage.getPosition().get().z);
    if (to == null) return;
  
    //focus on it
    focus(to);
  
    //reset flag
    mouseWasPressed = false;
  }
  
  //check if it is time to unfocus the word
  if (millis() > lastFocus+UNFOCUS_TIMER_INTERVAL)
    unfocus();

  //autoplay
  if (!autoplay && (millis() > lastFocus+FIRST_AUTOPLAY_TIMER_INTERVAL))
    autoplay = true;
  
  if (autoplay && (millis() > lastAutoplay+AUTOPLAY_TIMER_INTERVAL))
    nextAutoplay();
    
  if (autoplay && Book.mouse.isPressed(LEFT) && (millis() > lastAutoplay+AUTOPLAY_RELEASE_TIMER))
    releaseMouse();
  
//  if (showPrompt)
//    renderer.renderPage(book.getPage(PROMPT_PAGE));

  //check if it is time to show/hide the prompt
//  if (millis() > lastFocus+PROMPT_TIMER_INTERVAL) {
//    if (!showPrompt)
//      addPromptText();
//    showPrompt = true;
//  } else
//    showPrompt = false;
  
  if (showFrameRate)
    showFrameRate();
}

void nextAutoplay() {
  //if we don't have an object yet pick one from the start
  TextObject autoplayObj = (TextObject)autoplayObjs.get(autoplayLine++);
  if (autoplayLine >= autoplayObjs.size()) autoplayLine = 0;
  
  //focus on the object
  focus(autoplayObj);
  
  //fake the mouse position so that the object is not outside the screen
  Rectangle bounds = autoplayObj.getBounds();
  int mX = int((int)bounds.getX() + (float)bounds.getWidth()/2);
  int mY = int((int)bounds.getY() + (float)bounds.getHeight()/2);
  if (bounds.getX() < 100) { mX = (int)(bounds.getWidth()/2) + (int)random(100, 150); }
  if (bounds.getY() < 100) { mY = (int)(bounds.getHeight()) + (int)random(100, 150); }
  if (bounds.getX()+bounds.getWidth() > width) { mX = (int)bounds.getX() + (int)(bounds.getWidth()/2) - (int)random(150, 200); }
  if (bounds.getY()+bounds.getHeight() > height) { mY = (int)bounds.getY()+ (int)(bounds.getHeight()) - (int)random(150, 200); }
  
  MouseEvent me = new MouseEvent(this,
                                 MouseEvent.MOUSE_PRESSED,
                                 millis(),
                                 InputEvent.BUTTON1_MASK,
                                 mX,
                                 mY,
                                 1,
                                 false);
  Book.mouse.mouseEvent(me);
 
  //println(autoplayObj + " " + bounds); 
  //println(mX + ", " + mY);
 
  //keep track of last time
  lastAutoplay = millis();
}

void releaseMouse() {
  MouseEvent me = new MouseEvent(this,
                                 MouseEvent.MOUSE_RELEASED,
                                 millis(),
                                 InputEvent.BUTTON1_MASK,
                                 Book.mouse.getX(),
                                 Book.mouse.getY(),
                                 1,
                                 false);
  Book.mouse.mouseEvent(me);
}

void drawBook() {
    // render all the pages
    gl.glDisable(GL.GL_DEPTH_TEST);
    renderer.renderPage(book.getPage(CENTER_PAGE));
    gl.glEnable(GL.GL_DEPTH_TEST);
    renderer.renderPage(book.getPage(UNFOCUS_PAGE));
    renderer.renderPage(book.getPage(FOCUS_PAGE));
}

void keyPressed() {
  switch(key) {
    case '1':
      showFrameRate = !showFrameRate;
      break;
    /*case ENTER:
      if (!mmOutput) {
        println("Start recording...");
        mm = new MovieMaker(this, width, height, "TheThingsYouveSaid.mov",
                            FPS, MovieMaker.ANIMATION, MovieMaker.LOSSLESS);
        mmOutput = true;
      } else {
        println("End recording.");
        mm.finish();
        mmOutput = false;
      }
      break;
    case ' ':
      println("Save frame " + frameCount);
      saveFrame("TheThingsYouveSaid_" + frameCount + ".png");
      break;*/
    }
}

//mouse pressed
void mousePressed() {
  println("mouse pressed");
  if (PQLABS_TOUCHSCREEN) return;
  mousePressed(0, mouseX, mouseY); 
}

void mousePressed(int id, int x, int y) {   
  if (id != 0) return;

  mouseWasPressed = true;
  mouseWasPressedPt.set(x, y, 0);
  
  /*
  //stop autoplay
  autoplay = false;
  
  //get the top word
  TextPage centerPage = book.getPage(CENTER_PAGE);
  TextObject to = getTopWord(centerPage.getTextRoot(), x, y, (int)centerPage.getPosition().get().z);
  if (to == null) return;
  
  //focus on it
  focus(to);
  */
}

void mouseMoved() {
  //update the timer to make sure the focused word
  //doesn't unfocus if the user is moving it around
  lastFocus = millis();
  autoplay = false;
}

void mouseDragged() {
  println("mouse dragged");
  if (PQLABS_TOUCHSCREEN) return;
  mouseDragged(0, mouseX, mouseY);
}

void mouseDragged(int id, int x, int y) {
  if (id != 0) return;

  mouseMoved();
  if (focusedWord == null)
    mousePressed(id, x, y);
}

void mouseReleased(int id, int x, int y) {
  println("mouse released");
  //do nothing
}

void focus(TextObject to) {
  //if some word are still unfocusing we block focus
  if (unfocusedWord != null) return;
  
  //if the word already has focus, do nothing
  BooleanProperty focusProperty = (BooleanProperty)to.getProperty("Focus");
  if (focusProperty.get()) return;

//  //stop autoplay
//  autoplay = false;

  //set Unfocus property of the clicked word to false
  BooleanProperty unfocusProperty = (BooleanProperty)to.getProperty("Unfocus");
  unfocusProperty.set(false);
  
  //reset the behaviours of its siblings (same line)
  NumberProperty lineProp = (NumberProperty)to.getProperty("Line");
  int matchLine = (int)lineProp.get();

  //reset the behaviour for the objects
  focusMulti.reset(to);
  sameChain.complete(to);
   
  TextPage centerPage = book.getPage(CENTER_PAGE);   
  TextObjectIterator it = centerPage.getTextRoot().iterator();
  TextObject sto;
  while(it.hasNext()) {
    sto = it.next();
    lineProp = (NumberProperty)sto.getProperty("Line");
    if ((lineProp != null) && (lineProp.get() == matchLine)) {
      sameChain.complete(sto);
    }
  }
 
  //unfocus the current focused word
  unfocus();

  //set the line to control how the words on the same line
  //as the focus word behave
  slowFadeOnFocusLine.setLine(matchLine);
  wanderOnFocusLine.setLine(matchLine);
  unfocusSameOnFocusLine.setLine(matchLine);
  unfocusOnFocusLine.setLine(matchLine);
  
  //move the focus page to its original position
  book.getPage(FOCUS_PAGE).getPosition().set(FOCUS_PAGE_POSITION);
  
  //move it to the focus page
  adopt(to, book.getPage(FOCUS_PAGE).getTextRoot());

  //save the new focused word for later
  focusedWord = to;

  //keep track of last focus time    
  lastFocus = millis();
  
  //set Focus property of the clicked word to true
  focusProperty.set(true); 
}

void unfocus() {
  if (focusedWord == null) return;

  unfocusedWord = focusedWord;
  
  //set the line to control how the words on the same line
  //as the focus word behave
  slowFadeOnFocusLine.setLine(-1);
  wanderOnFocusLine.setLine(-1);
  unfocusSameOnFocusLine.setLine(-1);
  unfocusOnFocusLine.setLine(-1);

  //get the centerpage
  TextPage centerPage = book.getPage(CENTER_PAGE);
  
  //set the Focus property the the last word in focus to false
  BooleanProperty focusProperty = (BooleanProperty)focusedWord.getProperty("Focus");
  focusProperty.set(false);
  
  //reset bahviours of the focusedWord
  unfocusMulti.reset(focusedWord);
  unfocusChain.complete(focusedWord);
  unfocusColorChain.complete(focusedWord);
  unfocusSameColorChain.complete(focusedWord);
   
  //reset the behaviours of its siblings (same line)
  NumberProperty lineProp = (NumberProperty)focusedWord.getProperty("Line");
  int matchLine = (int)lineProp.get();
    
  TextObjectIterator it = centerPage.getTextRoot().iterator();
  TextObject sto;
  while(it.hasNext()) {
    sto = it.next();
    lineProp = (NumberProperty)sto.getProperty("Line");
    if ((lineProp != null) && (lineProp.get() == matchLine)) {
      unfocusSameColorChain.complete(sto);
      sto.getColor().set(colorToColor(sameTextFgFillClr));
      sto.getStrokeColor().set(colorToColor(sameTextFgStrokeClr));
    }
  }
   
  //move the unfocus page to its original position
  book.getPage(UNFOCUS_PAGE).getPosition().set(book.getPage(FOCUS_PAGE).getPosition().get());
  
  //move it to the focus page
  adopt(focusedWord, book.getPage(UNFOCUS_PAGE).getTextRoot());
  
  //set the Unfocus property the the last word in focus to true
  BooleanProperty unfocusProperty = (BooleanProperty)focusedWord.getProperty("Unfocus");
  unfocusProperty.set(true);   

  //clean up
  focusedWord = null;
}

TextObject getTopWord(TextObjectGroup root, int x, int y, int z) {
  if (root == null) return null;

  //check if we pressed on the focused word
  if ((focusedWord != null) && (focusedWord.getBoundingPolygon().contains(x, y)))
    return focusedWord;
  
  //check all others
  TextObjectGlyphIteratorBack it = new TextObjectGlyphIteratorBack(root);
  TextObject to;
  TextObjectGroup grp;
  BooleanProperty focusProperty;
  while(it.hasNext()) {
    to = it.next();
    grp = to.getParent().getParent();
    focusProperty = (BooleanProperty)grp.getProperty("Focus");
    if (focusProperty.get()) continue;
    if (screenRect(to.getBoundingPolygon().getBounds(), z).contains(x, y)) return grp;
  }
  
  return null;
}

void adopt(TextObject child, TextObjectGroup parent) {
  PVector prevAbsPos = child.getPositionAbsolute();
  Color prevColor = child.getColorAbsolute();

  child.detach();
  parent.attachChild(child);

  PVector newAbsPos = child.getPositionAbsolute();
  child.getPosition().add(new PVector(prevAbsPos.x-newAbsPos.x, prevAbsPos.y-newAbsPos.y, prevAbsPos.z-newAbsPos.z));
  child.getColor().set(prevColor);
}

private Rectangle screenRect(Rectangle bounds, float z) {
  int sX1 = (int)screenX((int)bounds.getX(), (int)bounds.getY(), z);
  int sY1 = (int)screenY((int)bounds.getX(), (int)bounds.getY(), z);
  int sX2 = (int)screenX((int)bounds.getX()+(int)bounds.getWidth(), (int)bounds.getY()+(int)bounds.getHeight(), z);
  int sY2 = (int)screenY((int)bounds.getX()+(int)bounds.getWidth(), (int)bounds.getY()+(int)bounds.getHeight(), z);
  return new Rectangle(sX1, sY1, sX2-sX1, sY2-sY1);
}

void loadTexts() {
  //load text files
  for(int i = 0; i < TEXT_FILES.length; i++) {
    print("Loading text #" + (i+1) + "... ");

    String[] strings = loadStrings(TEXT_FILES[i]);
    TEXTS[i] = new ArrayList();
    for(int j = 0; j < strings.length; j++) {
      TEXTS[i].add(strings[j]);
    }

    print("Done (" + TEXTS[i].size() + " line");
    if (TEXTS[i].size() > 1) print("s");
    println(")");
  }
}

void addCenterText() {
  RandomMotion randomMotion = new RandomMotion(1.0);
  Wander wanderMore = new Wander(0.25, 100, 10);
  Wander wanderLess = new Wander(0.1, 50, 10);

  //chain of behaviour for an object that is grabbed in focus
  focusMulti = new Multiplexer();
  focusMulti.add(new TransportPage(book.getPage(FOCUS_PAGE), new PVector(0, 0, 0), PAGE_FORWARD_SPEED));
  focusMulti.add(new OnMouseDepressed(new Approach(book.mouse, 4, 25, false)));
  focusMulti.add(new Colorize(colorToColor(textFgFillClr), FADE_IN_SPEED,
                              colorToColor(textFgStrokeClr), FADE_IN_SPEED));
  sameChain = new Chain();
  sameChain.add(new BringToFront());
  sameChain.add(new Colorize(colorToColor(sameTextFgFillClr), FADE_IN_BG_SPEED,
                             colorToColor(sameTextFgStrokeClr), FADE_IN_BG_SPEED));
  focusMulti.add(new ApplyToSame(book.getPage(CENTER_PAGE).getTextRoot(), sameChain));

  //chain of behaviour for an object that is released from focus
  unfocusMulti = new Multiplexer();
  unfocusMulti.add(new TransportPage(book.getPage(UNFOCUS_PAGE), FOCUS_PAGE_POSITION, PAGE_BACKWARD_SPEED));
  unfocusColorChain = new Chain();
  unfocusColorChain.add(new Colorize(colorToColor(color(102, 102, 145)), FADE_OUT_SPEED,
                                     colorToColor(color(0, 0, 0, 102)), FADE_OUT_SPEED));
  unfocusColorChain.add(new Colorize(colorToColor(color(145, 145, 145)), FADE_OUT_SPEED,
                                     colorToColor(color(0, 0, 0, 145)), FADE_OUT_SPEED));
  unfocusColorChain.add(new Colorize(colorToColor(textBgFillClr), FADE_OUT_SPEED,
                                     colorToColor(textBgStrokeClr), FADE_OUT_SPEED)); 
  unfocusOnFocusLine = new OnFocusLine(new DoNothing(),
                                       unfocusColorChain);
  unfocusMulti.add(unfocusOnFocusLine);

  unfocusSameColorChain = new Chain();
  unfocusSameColorChain.add(new Colorize(colorToColor(color(102, 102, 145)), FADE_OUT_BG_SPEED,
                                         colorToColor(color(0, 0, 0, 25)), FADE_OUT_BG_SPEED));
  unfocusSameColorChain.add(new Colorize(colorToColor(color(145, 145, 145)), FADE_OUT_BG_SPEED,
                                         colorToColor(color(0, 0, 0, 0)), FADE_OUT_BG_SPEED));
  unfocusSameColorChain.add(new Colorize(colorToColor(sameTextBgFillClr), FADE_OUT_BG_SPEED,
                                         colorToColor(sameTextBgStrokeClr), FADE_OUT_BG_SPEED));
  unfocusSameOnFocusLine = new OnFocusLine(new DoNothing(), unfocusSameColorChain);
  //unfocusSameOnFocusLine = new OnFocusLine(new DoNothing(), new Colorize(colorToColor(sameTextBgFillClr), FADE_OUT_BG_SPEED,
  //                                                                       colorToColor(sameTextBgStrokeClr), FADE_OUT_BG_SPEED));
  unfocusMulti.add(new ApplyToSame(book.getPage(CENTER_PAGE).getTextRoot(),
                                   unfocusSameOnFocusLine));
                                                 
  unfocusChain = new Chain();
  unfocusChain.add(unfocusMulti); 
  Multiplexer adoptMulti = new Multiplexer();
  //adoptMulti.add(new DebugLog("adopt multi"));
  adoptMulti.add(new Colorize(colorToColor(textNoFogBgStrokeClr), MAX_INT, false, true));
  adoptMulti.add(new Adopt(book.getPage(CENTER_PAGE).getTextRoot()));
  //adoptMulti.add(new SetUnfocus(false)); 
  unfocusChain.add(adoptMulti);
  unfocusChain.add(new SetUnfocus(false));

  Multiplexer mainMultiplexer = new Multiplexer();
  mainMultiplexer.add(new Move(0.1, 0));
  
  slowFadeOnFocusLine = new OnFocusLine(new DoNothing(),
                                        new OnMillisInterval(new Colorize(colorToColor(sameTextBgStrokeClr), 1, false, true), STROKE_FADE_INTERVAL));
  mainMultiplexer.add(new Repeat(slowFadeOnFocusLine));

  mainMultiplexer.add(new HasFocus(randomMotion, false));
  
  wanderOnFocusLine = new OnFocusLine(wanderLess, wanderMore);
  Wander wanderAroundMouse = new Wander(0.1, 50, 10, Book.mouse);
  mainMultiplexer.add(new HasFocus(wanderAroundMouse, wanderOnFocusLine, true));
  //mainMultiplexer.add(wanderOnFocusLine);
  
  mainMultiplexer.add(new HasFocus(focusMulti));
  //mainMultiplexer.add(new HasFocus(new StayInWindow(this)));
  mainMultiplexer.add(new HasUnfocus(unfocusChain));
  
  book.addGroupBehaviour(new Repeat(mainMultiplexer)); 

  ArrayList txt = TEXTS[0];
  noStroke();
  fill(textBgFillClr);
  textAlign(CENTER, BASELINE);
  textFont(font, fontSize);
 
  String[] tokens;
  TextObjectGroup newGroup;
  for(int i = 0; i < txt.size(); i++) {
    tokens = ((String)txt.get(i)).split(" ");
    for(int j = 0; j < tokens.length; j++) {
      //is it an autoplay word
      boolean autoplayWord = false;
      if (tokens[j].charAt(0) == '*') {
        tokens[j] = tokens[j].substring(1);
        autoplayWord = true;
      }
      
      //disperse tokens
      newGroup = book.addText(tokens[j],
                              int(BG_OFFSET[0] + (j/(float)tokens.length)*(width+BG_OFFSET[2])),
                              int(BG_OFFSET[1] + (i/(float)txt.size())*(height+BG_OFFSET[3])) + (int)(fontSize/2) + int(random(-100, 100)),
                              CENTER_PAGE);
      newGroup.init("Line", new NumberProperty(i));
      
      //at to the autoplay list
      if (autoplayWord)
        autoplayObjs.add(newGroup);
    }
  }
  
  book.removeAllGroupBehaviours();
}

void addPromptText() {
  //clean up
  book.clearPage(PROMPT_PAGE);
  
  //prompt behaviours
  Multiplexer multi = new Multiplexer();
  multi.add(new Move(0.1, 0));  
  multi.add(new Wander(0.25, 100, 20));  
  
  //parameters
  noStroke();
  fill(promptFillClr);
  textAlign(CENTER, BASELINE);
  textFont(font, fontSize);
  
  //add the prompt
  //book.addWordBehaviour(multi);
  //book.addText(PROMPTS[promptIndex], width/2, height/2, PROMPT_PAGE);
  //book.removeAllWordBehaviours();
  //promptIndex = 1 - promptIndex;
}

void showFrameRate() {
  noStroke();
  fill(0, 255, 0);
  textFont(font24pt, 24);
  textAlign(LEFT);
  text(frameRate, 20, 30);
}

Color colorToColor(color c) {
  return new Color(int(red(c)), int(green(c)), int(blue(c)), int(alpha(c)));
}
