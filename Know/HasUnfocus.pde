
public class HasUnfocus extends Condition {
    
  boolean unfocus; 
  
  public HasUnfocus(net.nexttext.behaviour.Action trueAction) {
    this(trueAction, true);
  }

  public HasUnfocus(net.nexttext.behaviour.Action trueAction, boolean unfocus) {
    this(trueAction, new DoNothing(), unfocus);
  }

  public HasUnfocus(net.nexttext.behaviour.Action trueAction, net.nexttext.behaviour.Action falseAction, boolean unfocus) {
    super(trueAction, falseAction);
    this.unfocus = unfocus;
  }

  public boolean condition(TextObject to) {
    BooleanProperty unfocusProperty = (BooleanProperty)to.getProperty("Unfocus");
    return unfocusProperty.get() == unfocus;
  }
}

