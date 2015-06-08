
public class HasFocus extends Condition {
    
  boolean focus; 
  
  public HasFocus(net.nexttext.behaviour.Action trueAction) {
    this(trueAction, true);
  }

  public HasFocus(net.nexttext.behaviour.Action trueAction, boolean focus) {
    this(trueAction, new DoNothing(), focus);
  }

  public HasFocus(net.nexttext.behaviour.Action trueAction, net.nexttext.behaviour.Action falseAction, boolean focus) {
    super(trueAction, falseAction);
    this.focus = focus;
  }

  /**
   * Gets the set of properties required by all TTYSAction
   *
   * @return Map containing the properties
   */
  /*public Map getRequiredProperties() {
    Map properties = super.getRequiredProperties();

    BooleanProperty focus = new BooleanProperty(false);
    properties.put("Focus", focus);

    return properties;
  }*/
    
  public boolean condition(TextObject to) {
    BooleanProperty focusProperty = (BooleanProperty)to.getProperty("Focus");
    return focusProperty.get() == focus;
  }
}

