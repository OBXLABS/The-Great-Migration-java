public class Wander extends PhysicsAction {
  
  Locatable locatableTarget;
  
  /**   
   * Constructor.
   * @param speed controls the magnitude of the acceleration applied in the direction
   * of the target
   * @param hitRange this value is used as a radius around the target to 
   * determine if Approach has reached its location.  A hitRange of 1 means 
   * that Approach will not return done unless the object is right on target.  
   */
   public Wander( float speed, float radius, int hitRange ) {
     this(speed, radius, hitRange, null);
   }

   public Wander( float speed, float radius, int hitRange, Locatable target ) {
     properties().init("Speed", new NumberProperty(speed));
     properties().init("Radius", new NumberProperty(radius));
     //properties().init("AngularSpeed", new NumberProperty( angularSpeed ));
     properties().init("HitRange", new NumberProperty(hitRange));
     this.locatableTarget = target;
   }
   
    /**
     * Applies an acceleration towards the target, with a magnitude proportional
     * to the Speed property.
     * 
     * <p>Result is complete if it has reached its target. </p>
     */
    public ActionResult behave(TextObject to) {
      NumberProperty speed = (NumberProperty)properties().get("Speed");
      NumberProperty radius = (NumberProperty)properties().get("Radius");
      NumberProperty hitRange = (NumberProperty)properties().get("HitRange");
      PVectorProperty position = to.getPosition();
      
      //get the last target of the text object
      PVector target = (PVector)textObjectData.get(to);
      if (target == null) {
        if (locatableTarget == null)
          target = position.getOriginal();
        else
          target = locatableTarget.getLocation();
        target.add(cos(random(TWO_PI))*radius.get(), sin(random(TWO_PI))*radius.get(), 0);
        textObjectData.put(to, target);
      }
            
      // get the vector from the abs position to the target               
      PVector pos = position.get();
      PVector dir = target.get();
      dir.sub(pos);	 	
	 	
      // get the distance from the target as a scalar value
      float distance = dir.mag();
                
      if ( distance > hitRange.get() ) {
        // apply an acceleration in the direction of the target                  
        dir.mult( (1 / distance) * speed.get() );
        applyAcceleration(to, dir);
        return new ActionResult(false, false, false);
      }
      // the object is close enough to the target, we are done 
      else{
        //move target
        if (locatableTarget == null)
          target = position.getOriginal();
        else
          target = locatableTarget.getLocation();
        target.add(cos(random(TWO_PI))*radius.get(), sin(random(TWO_PI))*radius.get(), 0);
        textObjectData.put(to, target);

        return new ActionResult(false, false, false);
      }
   }
}

