//import java.util.Map;

/**
 * Parent Action for all I Will Follow actions.
 *
 * <p>Adds the Leader and Follower properties to the set of basic properties.</p>
 */
public class TTYSAction extends AbstractAction {
    
    /**
     * Gets the set of properties required by all TTYSAction
     *
     * @return Map containing the properties
     */
    public Map getRequiredProperties() {
        Map properties = super.getRequiredProperties();

        BooleanProperty focus = new BooleanProperty(false);
        properties.put("Focus", focus);

        BooleanProperty unfocus = new BooleanProperty(false);
        properties.put("Unfocus", unfocus);

        return properties;
    }

    
    /**
     * Gets the value of the Focus property
     *
     * @param to the concerned TextObject
     *
     * @return BooleanProperty whether this TextObject has the property or not
     */
    public BooleanProperty getFocus(TextObject to) {
        return (BooleanProperty)to.getProperty("Focus");
    }

    /**
     * Gets the value of the Unfocus property
     *
     * @param to the concerned TextObject
     *
     * @return BooleanProperty whether this TextObject has the property or not
     */
    public BooleanProperty getUnfocus(TextObject to) {
        return (BooleanProperty)to.getProperty("Unfocus");
    }
}
