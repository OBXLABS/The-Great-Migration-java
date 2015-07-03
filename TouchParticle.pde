/**
 * Graphical object released under touches.
 Copyright (C) <2015>  <Jason Lewis>
  
    This program is free software: you can redistribute it and/or modify
    it under the terms of the BSD 3 clause with added Attribution clause license.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   BSD 3 clause with added Attribution clause License for more details.
 */
public class TouchParticle extends KineticObject { 
  float[][] fVertices;  //vertices for the texture
  float fScale;         //scale of texture
  PGraphics tex;        //the texture
  color clr;            //color
  float clrAlpha;       //color's alpha (separate for fading)
  float fadeRate;       //fading rate

  //constructor
  public TouchParticle() {
    //create the default texture
    tex = createGraphics(8, 8, P2D);
    setColor(0);
    fadeRate = 0;
    fScale = 20;
    fVertices = new float[2][4];
    for(int i = 0; i < 2; i++)
      for(int j = 0; j < 4; j++)
        fVertices[i][j] = 1.0 + random(-0.4, 0.4);
  }
  
  //set color
  public void setColor(color c) {
    clr = c;
    clrAlpha = alpha(c);
    updateTexture();
  }
  
  //update the texture
  private void updateTexture() {
    tex.beginDraw();
    tex.background(clr);
    tex.endDraw();
  }
  
  //set the scale
  public void setScale(float s) { fScale = s; }
  
  //set fading rate
  public void setFadeRate(float f) { fadeRate = f; }
  
  //update
  public void update(long dt) {
    super.update(dt);
    
    if (clrAlpha > 0) {
      clrAlpha -= fadeRate*dt;
      if (clrAlpha < 0) clrAlpha = 0;
      clr = color(red(clr), green(clr), blue(clr), (int)clrAlpha);
      updateTexture();
    }
  }
  
  //draw
  public void draw() {
    pushMatrix();
    translate(pos.x,pos.y);
    scale(fScale);
    rotate(ang);
    beginShape(QUADS);
    texture(tex);
    vertex(-fVertices[0][0],-fVertices[1][0],0,0,0);
    vertex(fVertices[0][1],-fVertices[1][1],1,0);
    vertex(fVertices[0][2],fVertices[1][2],0,1,1);
    vertex(-fVertices[0][3],fVertices[1][3],0,0,1);
    endShape(CLOSE);
    popMatrix();
  }
}
