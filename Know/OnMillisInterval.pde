
public class OnMillisInterval extends Condition {
    
  long interval;
  
  public OnMillisInterval(net.nexttext.behaviour.Action trueAction, long interval) {
    this(trueAction, new DoNothing(), interval);
  }

  public OnMillisInterval(net.nexttext.behaviour.Action trueAction, net.nexttext.behaviour.Action falseAction, long interval) {
    super(trueAction, falseAction);
    this.interval = interval;
  }
    
  public boolean condition(TextObject to) {
    Long startTime = (Long)textObjectData.get(to);
    if (startTime == null) {
      textObjectData.put(to, new Long(millis()));
      return false;
    }
    
    long now = millis();
    if ((now - startTime.longValue()) >= interval) {
      textObjectData.put(to, new Long(now));
      return true;
    }
    else {
      return false;
    }
  }
}

