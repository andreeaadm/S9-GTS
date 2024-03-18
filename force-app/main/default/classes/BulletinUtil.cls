public with sharing class BulletinUtil {
  public static final String pinnedType = 'Pinned';
  public static final String unpinnedType = 'Unpinned';
  public static final String sentType = 'Sent';
  private static final String pinnedClause = ' Pinned__c = TRUE';
  private static final String notPinnedClause = ' Pinned__c = FALSE';
  private static final String activeClause = ' Active__c = TRUE';
  private static final String brandAudienceClause = ' Target_Audience__c INCLUDES (\'Brands\')';
  private static final String supplierAudienceClause = ' Target_Audience__c INCLUDES (\'Suppliers\')';
  private static final String supplierSentByClause = ' (Sent_From_Owner_Account__c IN :brandIds OR Sent_by_Intertek__c = TRUE)';
  private static final String sentByIntertekClause = ' Sent_by_Intertek__c = TRUE';
  private static final String brandSentByClause = ' Sent_From_Owner_Account__c = ';

  private class BulletinTypeNotFoundException extends Exception {
  }

  public static List<Bulletin__c> getBulletins(
    Integer rowLimit,
    String context
  ) {
    String soql = 'SELECT Subject__c, Sent_From_Owner_Account__r.Name, Sent_Date__c, Description__c, Active__c, Pinned__c, Sent_by_Intertek__c, Sent_From_Owner_Account__c, Target_Audience__c, From__c FROM Bulletin__c';

    TC_ExperienceCloud current = new TC_ExperienceCloud();

    String accountIdAsStr = '';
    Id accountId;
    if(current.user.Contact.Account.ToxClear_Account_Type__c == 'Supplier' || 
    current.user.Contact.Account.ToxClear_Account_Type__c == 'Brand'){
      accountIdAsStr = current.user.Contact.AccountId;
    }
    else if(current.user.Contact.Account.ToxClear_Account_Type__c == 'Facility'){
      accountIdAsStr = current.user.Contact.Account.ParentId;
    }
     if(String.IsNotEmpty(accountIdAsStr)){
        accountId = Id.valueOf(accountIdAsStr);
     }
    

    soql += getSoql(
      context,
      current.isSupplierUser,
      current.isBrandUser,
      accountId
    );
    soql += ' ORDER BY Sent_Date__c DESC';

    if (rowLimit != null) {
      soql += ' LIMIT ' + rowLimit;
    }

    return (List<Bulletin__c>) Database.query(soql);
  }

  private static String getSoql(
    String context,
    Boolean isSupplierUser,
    Boolean isBrandUser,
    Id currentAccountId
  ) {
    if (isSupplierUser || isBrandUser) {
      String soql = ' WHERE';
      if (
        isSupplierUser && (context == pinnedType || context == unpinnedType)
      ) {
        soql +=
          activeClause +
          ' AND' +
          supplierAudienceClause +
          ' AND' +
          constructSupplierSentByClause(currentAccountId) +
          ' AND' +
          (context == pinnedType ? pinnedClause : notPinnedClause);
        return soql;
      } else if (isBrandUser) {
        if (context == sentType) {
          soql +=
            activeClause +
            ' AND' +
            brandSentByClause +
            '\'' +
            String.valueOf(currentAccountId) +
            '\'';
          return soql;
        } else if (context == pinnedType || context == unpinnedType) {
          soql +=
            brandAudienceClause +
            ' AND' +
            (context == pinnedType ? pinnedClause : notPinnedClause);
          return soql;
        }
      }
    }
    throw new BulletinTypeNotFoundException();
  }

  private static String constructSupplierSentByClause(Id currentAccountId) {
    List<Brand_Supplier_Connection__c> connections = [
      SELECT Brand_Account__c
      FROM Brand_Supplier_Connection__c
      WHERE
        Active__c = TRUE
        AND Status__c = 'Approved'
        AND Supplier_Account__c = :currentAccountId
    ];

    if (connections.size() > 0) {
      Set<String> brandIds = new Set<String>();
      for (Brand_Supplier_Connection__c connection : connections) {
        brandIds.add(connection.Brand_Account__c);
      }

      String brandIdList =
        '(\'' +
        String.join(new List<String>(brandIds), '\',\'') +
        '\')';

      return ' (Sent_From_Owner_Account__c IN ' +
        brandIdList +
        ' OR' +
        sentByIntertekClause +
        ')';
    } else {
      return sentByIntertekClause;
    }
  }
}