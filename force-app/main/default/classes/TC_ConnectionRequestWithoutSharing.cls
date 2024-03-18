public without sharing class TC_ConnectionRequestWithoutSharing {
  // Returning map of Integer to List<Account>, Integer being the max count of valid accounts, List<Account> being the accounts to put in the table
  public static Map<Integer, List<Account>> getAccounts(
    String userType,
    Integer amountToShow,
    String nameSearch,
    String countrySearch
  ) {
    User currentUser = [
      SELECT Contact.AccountId
      FROM User
      WHERE Id = :UserInfo.getUserId()
    ];
    String queryString =
      'SELECT Id, Name, toLabel(Country__c), (SELECT Id FROM Brand_Supplier_Connections__r WHERE (Status__c = \'Requested\' OR Status__c = \'Approved\') AND ' + (userType == 'supplier' ? 'Supplier_Account__c' : 'Brand_Account__c') + ' = \'' + currentUser.Contact.AccountId + '\'), (SELECT Id FROM Brand_Supplier_Connections1__r WHERE (Status__c = \'Requested\' OR Status__c = \'Approved\') AND ' + (userType == 'supplier' ? 'Supplier_Account__c' : 'Brand_Account__c') + ' = \'' + currentUser.Contact.AccountId + '\') FROM Account WHERE Is_ToxClear_Account__c = true AND ToxClear_Account_Type__c = \'' +
      (userType == 'supplier' ? 'Brand' : 'Supplier') +
      '\'';
    if (!String.isBlank(nameSearch)) {
      queryString +=
        ' AND Name LIKE \'%' +
        String.escapeSingleQuotes(nameSearch) +
        '%\'';
    }
    if (!String.isBlank(countrySearch)) {
      queryString +=
        ' AND Country__c LIKE \'%' +
        String.escapeSingleQuotes(countrySearch) +
        '%\'';
    }
    List<Account> accountsToCheck = Database.query(queryString);

    List<Account> validAccounts = new List<Account>();
    for (Account a : accountsToCheck) {
      if (
        a.Brand_Supplier_Connections__r != null ||
        a.Brand_Supplier_Connections1__r != null
      ) {
        if (
          a.Brand_Supplier_Connections__r.isEmpty() &&
          a.Brand_Supplier_Connections1__r.isEmpty()
        ) {
          // Brand Supplier Connection list empty, no connections that fit criteria exist
          validAccounts.add(a);
        }
      } else {
        // Brand Supplier Connection list undefined, so no connections exist
        validAccounts.add(a);
      }
    }

    Integer maxCount = validAccounts.size();
    // Using this to avoid index out of bounds errors
    Integer maxToShow = (maxCount > amountToShow ? amountToShow : maxCount);
    List<Account> accountsToShow = new List<Account>();
    for (Integer i = 0; i < maxToShow; i++) {
      accountsToShow.add(validAccounts[i]);
    }

    Map<Integer, List<Account>> returnMap = new Map<Integer, List<Account>>();
    returnMap.put(maxCount, accountsToShow);
    return returnMap;
  }

  // Put into a method here to avoid insufficent access on cross reference entity errors
  public static void insertConnection(
    Brand_Supplier_Connection__c connectionToInsert
  ) {
    insert connectionToInsert;
  }
}