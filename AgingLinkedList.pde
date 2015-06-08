/**
 * A linked list of Kinetic Object that automatically removes
 * objects after a certain time. It also keeps a list of removed
 * objects to recycle them.
 */
public class AgingLinkedList {
  private LinkedList theList;      //list of objects
  private LinkedList recycledList; //list of recycled objects
  private long death;              //time in millis when objects die 
  
  //constructor
  public AgingLinkedList(long death) {
    theList = new LinkedList();
    recycledList = new LinkedList();
    this.death = death;
  }
  
  //get a list iterator
  public ListIterator listIterator() { return theList.listIterator(); }
  
  //add an object
  public void add(KineticObject obj) {
    theList.add(obj);
  }
  
  //update the list and its objects
  public void update(long dt) {
    ListIterator it = theList.listIterator();
    KineticObject obj;
    while(it.hasNext()) {
        obj = (KineticObject)it.next();
        obj.update(dt);
        
        //if the object is too old, then remove it
        //and recycle it
        if (obj.age() >= death) {
          obj.kill();
          it.remove();
          recycledList.add(obj);
        }
    }
  }
  
  //get a recycled object if any
  public KineticObject recycle() {
    if (recycledList.isEmpty()) return null;
    return (KineticObject)recycledList.removeFirst();
  }
}
