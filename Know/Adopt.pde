/**
 * Behaviour that switches the parent of a text object for a new one.
 */
public class Adopt extends AbstractAction {
  
    TextObjectGroup parent;
  
    /**
     * 
     * Creates a new instance of Adopt
     */
    public Adopt(TextObjectGroup parent) {
      this.parent = parent;
    }
   
    /** 
     * Switch a TextObject's parent.
     *
     * @param to the TextObject to act upon
     */
    public ActionResult behave(TextObject to) {
        PVector prevAbsPos = to.getPositionAbsolute();
        Color prevColor = to.getColorAbsolute();

        to.detach();
        parent.attachChild(to);

        PVector newAbsPos = to.getPositionAbsolute();
        to.getPosition().add(new PVector(prevAbsPos.x-newAbsPos.x, prevAbsPos.y-newAbsPos.y, prevAbsPos.z-newAbsPos.z));
        to.getColor().set(prevColor);
        
        //println("Adopt: " + parent);
        
        return new ActionResult(true, true, true);
    }  
}
