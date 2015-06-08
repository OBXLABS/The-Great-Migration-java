/**
 * Perform the given action on the TextObject's glyphs.
 *
 * <p>The given action is not performed on the TextObject passed to the behave
 * method, but rather on its glyphs.</p>
 *
 */
public class ApplyToSame extends AbstractAction {

    private TextObjectGroup root;
    private net.nexttext.behaviour.Action action;
    
    public ApplyToSame(TextObjectGroup root, net.nexttext.behaviour.Action action) {
        this.root = root;
        this.action = action;
    }

    /**
     * Apply the given action to the TextObject's descendants.
     *
     * <p>The results of the action calls are combined using the method
     * described in Action.ActionResult.  </p>
     */
    public ActionResult behave(TextObject to) {
      //ActionResult res = new ActionResult(false, true, true);
      ActionResult res = new ActionResult();
      TextObject sto;
      NumberProperty lineProp = (NumberProperty)to.getProperty("Line");
      int matchLine = (int)lineProp.get();
       
      TextObjectIterator it = root.iterator();
      while(it.hasNext()) {
        sto = it.next();
        lineProp = (NumberProperty)sto.getProperty("Line");
        if ((lineProp != null) && (lineProp.get() == matchLine)) {
          ActionResult tres = action.behave(sto); 
          res.combine(tres);
          //res.complete |= tres.complete;
        }
      }

      /*
       * see the ActionResult class for details on how
       * ActionResults are combined.
       */
      res.endCombine();
      if (res.complete){
          action.complete(to);
          complete(to);
      }
      return res;
    }

    /**
     * End this action for this object and end the passed in 
     * action for all its descendants.
     */
    public void complete(TextObject to) {
      super.complete(to);

      TextObject sto;
      NumberProperty lineProp = (NumberProperty)to.getProperty("Line");
      int matchLine = (int)lineProp.get();
      
      TextObjectIterator it = root.iterator();
      while(it.hasNext()) {
        sto = it.next();
        lineProp = (NumberProperty)sto.getProperty("Line");
        if ((lineProp != null) && (lineProp.get() == matchLine)) {
          action.complete(sto);
        }
      }
    }
}
