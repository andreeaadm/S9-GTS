/**
 * mocks Http responses using static resources for response body
 * @author Kevin Reader (oe:gen)
 * @date December 2021
 */
@isTest
public class StaticResourceMockResponseGenerator {
  /**
   * mocks a Http response using a StaticResource
   * @param staticResourceName - name of the StaticResource containing the mocked response
   * @param code - Http status code to add to the mock response
   * @param status - Http status to add to the mock response
   * @param responseHeaders - any Http headers expected in the response
   */
  public static void setMock(
    String staticResourceName,
    Integer code,
    String status,
    Map<String, String> responseHeaders
  ) {
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource(staticResourceName);
    mock.setStatusCode(code);
    mock.setStatus(status);
    if (responseHeaders != null) {
      for (String key : responseHeaders.keySet()) {
        mock.setHeader(key, responseHeaders.get(key));
      }
    }
    Test.setMock(HttpCalloutMock.class, mock);
  }
}