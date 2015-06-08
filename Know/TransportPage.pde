/**
 * Behaviour that moves a page.
 */
public class TransportPage extends AbstractAction {
    
    TextPage page;
    PVector hardTarget;
    Locatable locatableTarget;
    float speed;
    int firstFrame = -1;
    float zOffset = 200;
    boolean rotDirection = true;
  
    /**
     * 
     * Creates a new instance of TransportPage
     */
    public TransportPage(TextPage page, PVector target, float speed) {
      this.page = page;
      this.hardTarget = target;
      this.locatableTarget = null;
      this.speed = speed;
    }
    
    /**
     * Creates a new instance of a TransportPage that moves towards a Locatable target.
     */
    public TransportPage(TextPage page, Locatable target, float speed) {
      this.page = page;
      this.locatableTarget = target;
      this.hardTarget = null;
      this.speed = speed;
    }
   
   
    /** 
     * Switch a TextObject's parent.
     *
     * @param to the TextObject to act upon
     */
    public ActionResult behave(TextObject to) {
      PVectorProperty rotProperty = page.getRotation();
      PVector rot = rotProperty.get();
      PVectorProperty posProperty = page.getPosition();
      PVector pos = posProperty.get();
      
      //get the target, locatable or hard
      PVector target = locatableTarget == null ? hardTarget : locatableTarget.getLocation();
      
      float targetDist = pos.dist(target);
      
      if (targetDist != 0) {
        PVector toTarget = target.get();
        toTarget.sub(pos);
        
        //adjust the speed because of the page hack
        float adjSpeed = speed / (float)page.getTextRoot().getNumChildren();
        
        if (targetDist > adjSpeed) {
          toTarget.normalize();
          toTarget.mult(adjSpeed);
          posProperty.add(toTarget);
          
          if (firstFrame == -1)
            firstFrame = frameCount;
            
          float pageWidth = (float)page.getTextRoot().getBounds().getWidth();
          
          float rotAttenuator = pageWidth <= 50 ? 2 : 2 + (pageWidth-50)/250;
          float yRot = sin((target.z-posProperty.get().z)/zOffset*TWO_PI)/rotAttenuator;
          rotProperty.set(new PVector(0, rotDirection ? yRot : -yRot, 0));
        }
        else {
          posProperty.add(toTarget);
          rotProperty.set(new PVector());
          firstFrame = -1;
          //rotDirection = !rotDirection;
          return new ActionResult(true, true, false);              
        }
      } else {
        return new ActionResult(true, true, false);      
      }
      
      return new ActionResult(false, false, false);
    }  
}
