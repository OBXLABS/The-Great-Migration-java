/**
 * A linked list of Kinetic Object that automatically removes
 * objects after a certain time. It also keeps a list of removed
 * objects to recycle them.
 
 Copyright (C) <2015>  <Jason Lewis>
  
    This program is free software: you can redistribute it and/or modify
    it under the terms of the BSD 3 clause with added Attribution clause license.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   BSD 3 clause with added Attribution clause License for more details.
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
