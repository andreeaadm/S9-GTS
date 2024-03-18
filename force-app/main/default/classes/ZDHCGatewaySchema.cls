/**
 * base class for ZDHC Gateway request / response schema - allows dynamic property checks
 * @author Kevin Reader (oe:gen)
 * @date November 2021
 */
public abstract class ZDHCGatewaySchema {
  /**
   * gets a class property value
   * @param prop - name of the property requested
   * @return the current value of the property
   */
  public Object get(String prop) {
    Map<String, Object> objMap = (Map<String, Object>) JSON.deserializeUntyped(
      JSON.serialize(this)
    );
    return objMap.get(prop);
  }
}