/**
 * Perlin noise filled texture.
 */
public class PerlinTexture {
  long age;                         //age of the texture
  PGraphics tex;                    //the texture
  int texSize;                      //size
  int minRange, maxRange, range;    //min/max range to control contrast
  
  boolean NO_SCALE = false;         //true to render the texture 1:1, false for full sketch size

  /** Constructor. */
  public PerlinTexture() {
    age = 0;
    texSize = 128;
    tex = createGraphics(texSize, texSize, P2D);
    minRange = 50;
    maxRange = 200;
    range = maxRange-minRange;
  }

  /** Draw. */
  public void draw(int x, int y, int w, int h) {
    pgl = (PGraphicsOpenGL) g;
    gl = pgl.beginGL();
    gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_LINEAR);
    gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_LINEAR);
    pgl.endGL();

    pushMatrix();
    translate(x, y);
    if (NO_SCALE) scale(texSize, texSize);
    else scale(w, w);
    beginShape(QUADS);
    textureMode(NORMALIZED);
    texture(tex);
    vertex(-1,-1,0,0,0);
    vertex(1,-1,0,1,0);
    vertex(1,1,0,1,1);
    vertex(-1,1,0,0,1);
    endShape(CLOSE);
    popMatrix();
  }
  
  /** Update. */
  public void update(long dt) {
    age += dt;
    setNoise(tex);
  }
  
  /** Fill texture with noise. */
  public void setNoise(PGraphics pg) {
    noiseDetail(4, 0.4f);
    float fAge = age/10000f;
    
    for(int y = 0; y < pg.height; y++) {
      for(int x = 0; x < pg.width; x++) {
        pg.pixels[y*pg.width+x] = color(minRange + noise(x/20f - fAge, y/20f - fAge/4, fAge)*range);
      }
    }
    pg.updatePixels();
  }
}
