TextObject unfocusedWord = null;

public class SetUnfocus extends TTYSAction {
    
    boolean unfocus;
  
    /**
     * 
     * Creates a new instance of Adopt
     */
    public SetUnfocus(boolean f) {
      unfocus = f;
    }
   
    /** 
     * Switch a TextObject's parent.
     *
     * @param to the TextObject to act upon
     */
    public ActionResult behave(TextObject to) {
        BooleanProperty unfocusProperty = getUnfocus(to);

    	unfocusProperty.set(unfocus);
    
        if (unfocus && (unfocusedWord == null))
          unfocusedWord = to;
        else if (!unfocus && (unfocusedWord == to))
          unfocusedWord = null;

        return new ActionResult(true, true, true);
    }  
}
