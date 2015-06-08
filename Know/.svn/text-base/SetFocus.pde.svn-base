TextObject focusedWord = null;

public class SetFocus extends TTYSAction {
    
    boolean focus;
  
    /**
     * 
     * Creates a new instance of Adopt
     */
    public SetFocus(boolean f) {
      focus = f;
    }
   
    /** 
     * Switch a TextObject's parent.
     *
     * @param to the TextObject to act upon
     */
    public ActionResult behave(TextObject to) {
        BooleanProperty focusProperty = getFocus(to);

        if (focus && (focusedWord == null))
          focusedWord = to;
        else if (!focus && (focusedWord == to))
          focusedWord = null;
          
    	focusProperty.set(focus);
    
        return new ActionResult(true, true, true);
    }  
}
