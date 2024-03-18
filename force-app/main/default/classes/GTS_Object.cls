public abstract class GTS_Object extends GTS_RecordTypeService {
  protected Set<Id> sObjectListID;
  protected Set<Id> relatedJobsID;
  protected Set<Id> fullSobjectList;
  protected List<SObject> sObjectList;
  protected Map<Id, SObject> sObjectMap;
  protected Schema.SObjectType objectType;
  protected String recordGroup;
  protected Id recordTypeId;
  protected String recordTypeDeveloperName;
  protected SObject record;

  public static String GTS_GROUP = 'GTS';
  public static String ICARE_GROUP = 'iCare';
  public static String REQUEST = 'Request';
  public static String[] GROUPS = new List<String>{
    ICARE_GROUP,
    GTS_GROUP,
    Request
  };

  public GTS_Object() {
    this.fullSobjectList = new Set<Id>();
    this.sObjectListID = new Set<Id>();
  }

  public GTS_Object(Set<Id> fullSobjectList, Schema.SObjectType objectType) {
    this.fullSobjectList = fullSobjectList;
    this.objectType = objectType;
    this.setIdVariable();
  }

  public GTS_Object(SObject record) {
    this.record = record;
  }

  private void setIdVariable() {
    if (fullSobjectList != null && fullSobjectList.size() > 0) {
      for (Id entityId : fullSobjectList) {
        if (objectType == entityId.getSobjectType()) {
          sObjectListID = sObjectListID != null ? sObjectListID : new Set<Id>();
          sObjectListID.add(entityId);
        }
      }
    }
  }

  public Set<Id> getsObjectListID() {
    return this.sObjectListID;
  }

  public Map<Id, SObject> getSObjectMap() {
    return this.sObjectMap;
  }

  public abstract Set<Id> getRelatedJobsID();

  public abstract List<sObject> getSObjectListById();

  public abstract Map<String, List<sObject>> getByRecordTypeGroup(
    List<sObject> recordList
  );

  public String getRecordGroup(String process) {
    RecordType rt = [
      SELECT DeveloperName
      FROM RecordType
      WHERE Id = :recordTypeId
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
    this.recordTypeDeveloperName = rt.DeveloperName;
    for (String groupRecord : this.groupsByProcess(process)) {
      if (this.recordTypeDeveloperName.contains(groupRecord)) {
        this.recordGroup = groupRecord;
        break;
      }
    }
    return recordGroup;
  }
}