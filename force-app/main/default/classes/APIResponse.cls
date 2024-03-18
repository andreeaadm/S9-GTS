global class APIResponse {
  /**
   * Stores a List of message String objects.
   *
   * @var List<sObject>
   */
  @AuraEnabled
  global List<String> messages;

  /**
   * Stores an Object.
   *
   * @var Object
   */
  @AuraEnabled
  global Object obj;

  /**
   * Stores a List of sObject records.
   *
   * @var List<sObject>
   */
  @AuraEnabled
  global List<sObject> objList;

  /**
   * Stores a List of sObject records.
   *
   * @var Map<Id, sObject>
   */
  @AuraEnabled
  global Map<Object, sObject> objMap;

  /**
   * Stores the size of the objList variable.
   *
   * @var Integer
   */
  @AuraEnabled
  global Integer size;

  /**
   * Stores the response status.
   *
   * @var String
   */
  @AuraEnabled
  global String status;

  /**
   * Stores the response status code.
   *
   * @var Integer
   */
  @AuraEnabled
  global Integer statusCode;

  /**
   * Constructor.
   *
   * @param  String  status
   * @param  Integer  statusCode
   * @return void
   */
  global APIResponse(String status, Integer statusCode) {
    this.messages = null;
    this.obj = null;
    this.objList = null;
    this.objMap = null;
    this.size = (objList != null) ? objList.size() : 0;
    this.status = status;
    this.statusCode = statusCode;
  }

  /**
   * Constructor.
   *
   * @param  String  status
   * @param  Integer  statusCode
   * @param  String  message
   * @return void
   */
  global APIResponse(String status, Integer statusCode, String message) {
    this.messages = new List<String>{ message };
    this.objList = null;
    this.objMap = null;
    this.size = (objList != null) ? objList.size() : 0;
    this.status = status;
    this.statusCode = statusCode;
  }

  /**
   * Constructor.
   *
   * @param  String  status
   * @param  Integer  statusCode
   * @param  List<String>  messages
   * @return void
   */
  global APIResponse(String status, Integer statusCode, List<String> messages) {
    this.messages = messages;
    this.objList = null;
    this.objMap = null;
    this.size = (objList != null) ? objList.size() : 0;
    this.status = status;
    this.statusCode = statusCode;
  }

  /**
   * Constructor.
   *
   * @param  String  status
   * @param  Integer  statusCode
   * @param  sObject  obj
   * @return void
   */
  global APIResponse(String status, Integer statusCode, sObject obj) {
    this.messages = null;
    this.obj = null;
    this.objList = new List<sObject>{ obj };
    this.objMap = null;
    this.size = (objList != null) ? objList.size() : 0;
    this.status = status;
    this.statusCode = statusCode;
  }

  /**
   * Constructor.
   *
   * @param  String  status
   * @param  Integer  statusCode
   * @param  List<sObject>  objList
   * @return void
   */
  global APIResponse(String status, Integer statusCode, List<sObject> objList) {
    this.messages = null;
    this.obj = null;
    this.objList = objList;
    this.objMap = null;
    this.size = (objList != null) ? objList.size() : 0;
    this.status = status;
    this.statusCode = statusCode;
  }

  /**
   * Constructor.
   *
   * @param  String  status
   * @param  Integer  statusCode
   * @param  List<String>  messages
   * @param  List<sObject> objList
   * @return void
   */
  global APIResponse(
    String status,
    Integer statusCode,
    List<String> messages,
    List<sObject> objList
  ) {
    this.messages = messages;
    this.obj = null;
    this.objList = objList;
    this.objMap = null;
    this.size = (objList != null) ? objList.size() : 0;
    this.status = status;
    this.statusCode = statusCode;
  }

  /**
   * Constructor.
   *
   * @param  String  status
   * @param  Integer  statusCode
   * @param  Map<Object, sObject>  objMap
   * @return void
   */
  global APIResponse(
    String status,
    Integer statusCode,
    Map<Object, sObject> objMap
  ) {
    this.messages = null;
    this.obj = null;
    this.objList = null;
    this.objMap = objMap;
    this.size = (objList != null) ? objList.size() : 0;
    this.status = status;
    this.statusCode = statusCode;
  }
}