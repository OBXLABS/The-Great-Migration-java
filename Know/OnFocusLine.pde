
public class OnFocusLine extends Condition {
    
  int lineIndex = -1;  
  
  public OnFocusLine(net.nexttext.behaviour.Action trueAction) {
    this(trueAction, new DoNothing());
  }

  public OnFocusLine(net.nexttext.behaviour.Action trueAction, net.nexttext.behaviour.Action falseAction) {
    super(trueAction, falseAction);
    this.lineIndex = -1;
  }
  
  void setLine(int index) { lineIndex = index; }

  /**
   * Gets the set of properties required by all TTYSAction
   *
   * @return Map containing the properties
   */
  /*public Map getRequiredProperties() {
    Map properties = super.getRequiredProperties();

    NumberProperty lineProp = new NumberProperty(-1);
    properties.put("Line", lineProp);

    return properties;
  }*/
    
  public boolean condition(TextObject to) {
      NumberProperty lineProp = (NumberProperty)to.getProperty("Line");
      return lineIndex == (int)lineProp.get();
  }
}

