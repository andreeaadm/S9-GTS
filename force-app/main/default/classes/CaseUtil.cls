public with sharing class CaseUtil {
  public static List<Case> getCases(
    String orderBy,
    String whereClause,
    Integer rowLimit
  ) {
    String soql = 'SELECT Id, CaseNumber, Subject, Status, Priority FROM Case';
    if (!String.isEmpty(whereClause)) {
      soql += ' WHERE ' + whereClause;
    }
    if (!String.isEmpty(orderBy)) {
      soql += ' ORDER BY ' + orderBy;
    }
    if (rowLimit != null) {
      soql += ' LIMIT ' + rowLimit;
    }
    return new List<Case>((List<Case>)Database.query(soql));
  }
}