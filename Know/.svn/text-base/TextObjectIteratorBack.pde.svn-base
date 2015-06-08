import java.util.Stack;

public class TextObjectIteratorBack {

  // The state of the iteration is maintained in a stack, which has the next
  // node on top, with all of its ancestors to the top of them traversal
  // above it.  Getting the next node means returning the top of the stack,
  // then finding the next node to traverse and pushing it, and any
  // appropriate ancestors on top of the stack.

  Stack ancestors = new Stack();

  /** Construct an iterator over the group and its descendants. */
  TextObjectIteratorBack( TextObjectGroup group ) {
    descend(group);
  }

  // Push the provide TextObject, and all of its left descendants onto the
  // stack.  This causes the traversal to start at the bottom.
  private void descend(TextObject to) {
    while (to != null) {
      ancestors.push(to);
      if (to instanceof TextObjectGroup) {
        to = ((TextObjectGroup) to).getRightMostChild();
      } else {
        to = null;
      }
    }
  }

  /** If the traversal is complete. */
  public boolean hasNext() {
    return !ancestors.empty();
  }

  /** Get the next node in the traversal. */
  public TextObject next() {
    TextObject current = (TextObject) ancestors.pop();

    // Put the next object on the stack.  If we're returning the object
    // originally provided (the stack is empty), then there's nothing left
    // to traverse, so don't push anything onto the stack.  If there's no
    // right sibling, then the next object is the parent, which is already
    // on the stack.
    if ( (!ancestors.empty()) && (current.getLeftSibling() != null) ) {
      descend(current.getLeftSibling());
    }
    return current;
  }
}

