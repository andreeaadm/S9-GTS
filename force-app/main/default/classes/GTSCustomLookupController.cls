/**
 *  Custom apex class to fetch the data by provided parameters.
 *
 *  @since     Oct 2023
 *  @author    Globant
 */
public without sharing class GTSCustomLookupController {
  //Method to retrieve top 5 records by created date.
  //    @AuraEnabled(cacheable=true)
  //    public static list<sObject> fetchLookupData(String searchKey , String sObjectApiName, String filterFieldApiName, String filterValue) {
  //
  //        List<sObject> returnList = new List<sObject>();
  //        String sWildCardText = '%' + searchKey + '%';
  //        String filter = ((String.isNotBlank(filterFieldApiName) && String.isNotBlank(filterValue)) ? (' ' + filterFieldApiName + ' = \'' + filterValue + '\' AND ') : '');
  //        String sQuery = 'Select Id,Name From ' + sObjectApiName + ' Where ' + filter + ' Name Like : sWildCardText order by createdDate DESC LIMIT 5';
  //
  //        for (sObject obj: database.query(sQuery)) {
  //
  //            returnList.add(obj);
  //        }
  //
  //        return returnList;
  //    }

  @AuraEnabled(cacheable=true)
  public static list<ResponseWrapper> fetchLookupData(
    String searchKey,
    String sObjectApiName,
    String fieldsApiNameWithValueMap,
    String labelApiName,
    String valueApiName
  ) {
    List<ResponseWrapper> returnList = new List<ResponseWrapper>();
    String sWildCardText = '%' + searchKey + '%';
    Map<String, String> fieldsMap = (Map<String, String>) JSON.deserialize(
      fieldsApiNameWithValueMap,
      Map<String, String>.class
    );
    String filter = '';
    for (String key : fieldsMap.keySet()) {
      filter += ((String.isNotBlank(key) &&
        String.isNotBlank(fieldsMap.get(key)))
        ? (Schema.getGlobalDescribe()
              .get(sObjectApiName)
              .getDescribe()
              .fields.getMap()
              .get(key)
              .getDescribe()
              .getType() == DisplayType.BOOLEAN)
            ? (' ' + key + ' = ' + fieldsMap.get(key) + ' AND ')
            : (' ' + key + ' = \'' + fieldsMap.get(key) + '\' AND ')
        : '');
    }
    String sQuery =
      'Select ' +
      valueApiName +
      ',' +
      labelApiName +
      ' From ' +
      sObjectApiName +
      ' Where ' +
      filter +
      ' ' +
      labelApiName +
      ' Like : sWildCardText order by createdDate DESC LIMIT 5';
    System.debug('sQuery#####' + sQuery);

    for (sObject obj : database.query(sQuery)) {
      returnList.add(
        new ResponseWrapper(
          obj.get(valueApiName).toString(),
          obj.get(labelApiName).toString()
        )
      );
    }

    System.debug('returnList ' + returnList);
    return returnList;
  }

  @AuraEnabled
  public static ResponseWrapper fetchDefaultRecord(
    String recordId,
    String sObjectApiName,
    String fieldsApiNameWithValueMap,
    String labelApiName,
    String valueApiName
  ) {
    System.debug('fetchDefaultRecord');
    Map<String, String> fieldsMap = (Map<String, String>) JSON.deserialize(
      fieldsApiNameWithValueMap,
      Map<String, String>.class
    );
    String filter = '';
    for (String key : fieldsMap.keySet()) {
      filter += ((String.isNotBlank(key) &&
        String.isNotBlank(fieldsMap.get(key)))
        ? (' ' + key + ' = \'' + fieldsMap.get(key) + '\' AND ')
        : '');
    }
    String sRecId = recordId;
    String sQuery =
      'Select ' +
      valueApiName +
      ',' +
      labelApiName +
      ' From ' +
      sObjectApiName +
      ' Where ' +
      filter +
      ' ' +
      valueApiName +
      ' = : sRecId LIMIT 1';
    System.debug('sQuery#####' + sQuery);
    for (sObject obj : database.query(sQuery)) {
      return new ResponseWrapper(
        obj.get(valueApiName).toString(),
        obj.get(labelApiName).toString()
      );
    }

    return null;
  }

  public class ResponseWrapper {
    @AuraEnabled
    public String Id;
    @AuraEnabled
    public String Name;
    public ResponseWrapper(String Id, String Name) {
      this.Id = Id;
      this.Name = Name;
    }
  }
}