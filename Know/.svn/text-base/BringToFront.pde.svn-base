public class BringToFront extends AbstractAction {

    public BringToFront() {
    }

    public ActionResult behave(TextObject to) {
      //get the parent
      TextObjectGroup parent = to.getParent();
      if (parent == null)
        return new ActionResult(false, false, false);
        
      to.detach();
      parent.attachChild(to);
      return new ActionResult(true, true, true);
    }
}
