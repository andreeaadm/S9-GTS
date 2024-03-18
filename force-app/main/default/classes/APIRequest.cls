public class APIRequest {
    /**
     * Stores the body as a String.
     *
     * @var String
     */
    public String body;

    /**
     * Stores the headerMap as a Map of String to String.
     *
     * @var Map<String, String>
     */
    public Map<String, String> headerMap;

    /**
     * Stores the status as a String.
     *
     * @var String
     */
    public String status;

    /**
     * Stores the statusCode as an Integer.
     *
     * @var Integer
     */
    public Integer statusCode;

    /**
     * Constructor.
     *
     * @param  String  status
     * @param  Integer  statusCode
     * @return APIRequest
     */
    public APIRequest(String status, Integer statusCode) {
        this.body = null;
        this.headerMap = null;
        this.status = status;
        this.statusCode = statusCode;
    }

    /**
     * Constructor.
     *
     * @param  Map<String, String>  headerMap
     * @param  String  status
     * @param  Integer  statusCode
     * @return APIRequest
     */
    public APIRequest(Map<String, String> headerMap, String status, Integer statusCode) {
        this.body = null;
        this.headerMap = headerMap;
        this.status = status;
        this.statusCode = statusCode;
    }

    /**
     * Constructor.
     *
     * @param  String  body
     * @param  String  status
     * @param  Integer  statusCode
     * @return APIRequest
     */
    public APIRequest(String body, String status, Integer statusCode) {
        this.body = body;
        this.headerMap = null;
        this.status = status;
        this.statusCode = statusCode;
    }

    /**
     * Constructor.
     *
     * @param  String  body
     * @param  Map<String, String>  headerMap
     * @param  String  status
     * @param  Integer  statusCode
     * @return APIRequest
     */
    public APIRequest(String body, Map<String, String> headerMap, String status, Integer statusCode) {
        this.body = body;
        this.headerMap = headerMap;
        this.status = status;
        this.statusCode = statusCode;
    }
}