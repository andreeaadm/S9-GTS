public with sharing class ReportDeliverableListController {
  @AuraEnabled
  public static ListResponse getTableData(
    Integer rowLimit,
    String orderBy,
    List<String> selectedRowIds,
    Id reportId
  ) {
    DataTable.Table returnData = new DataTable.Table();
    try {
      String soql =
        'SELECT Name, MTC_Status__c, Type__c' +
        ' FROM Asset' +
        ' WHERE Parent.Is_Hidden_By_Intertek__c = FALSE AND ParentId = \'' +
        reportId +
        '\'';

      soql += (orderBy != null && orderBy != '') ? ' ORDER BY ' + orderBy : '';
      soql += ' LIMIT ' + rowLimit;

      List<DataTable.Column> columns = new List<DataTable.Column>();
      List<DataTable.Row> rows = new List<DataTable.Row>();

      columns = getColumns(orderBy);
      rows = getRows(soql, selectedRowIds);

      returnData.columns = columns;
      returnData.rows = rows;
      return new ListResponse(returnData, rows.size());
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
      return null;
    }
  }

  private static List<DataTable.Column> getColumns(String orderBy) {
    List<DataTable.Column> columns = new List<DataTable.Column>{
      new DataTable.Column('Name', 'Deliverable name', ''),
      new DataTable.Column('MTC_Status__c', 'Status', ''),
      new DataTable.Column('Type__c', 'Type', ''),
      new DataTable.Column('Remove', 'Remove')
    };

    return columns;
  }

  private static List<DataTable.Row> getRows(
    String soql,
    List<String> selectedRowIds
  ) {
    List<DataTable.Row> rows = new List<DataTable.Row>();
    for (Asset deliverable : (List<Asset>) Database.query(soql)) {
      List<DataTable.Cell> rowCells = new List<DataTable.Cell>{
        new DataTable.Cell('Name', deliverable.Name, 'Deliverable name'),
        new DataTable.Cell(
          'MTC_Status__c',
          deliverable.MTC_Status__c,
          'Status'
        ),
        new DataTable.Cell('Type__c', deliverable.Type__c, 'Type'),
        new DataTable.Cell(
          'Download',
          'Download',
          null,
          true,
          true,
          false,
          'Download',
          'customEvent',
          'IntkBrandTwoBtn',
          'Download'
        )
      };

      rows.add(new DataTable.Row(deliverable.Id, rowCells));
    }
    return rows;
  }

  @AuraEnabled
  public static Map<String, String> downloadDeliverable(
    Id reportId,
    Id deliverableId
  ) {
    Http http = new Http();
    HttpRequest request = new HttpRequest();
    HttpResponse response;
    Map<String, String> result = new Map<String, String>();
    String b64encDoc;
    String documentName;

    List<Asset> deliverables = [
      SELECT
        Name,
        TruTesta_ID__c,
        Parent.Name,
        Parent.TruTesta_ID__c,
        Account.TruTesta_ID__c
      FROM Asset
      WHERE Id = :deliverableId AND ParentId = :reportId
    ];

    if (deliverables.isEmpty()) {
      return new Map<String, String>();
    }

    Asset deliverable = deliverables[0];

    String mulesoftEndpoint = OrgUtil.isProduction()
      ? Label.System_Mulesoft_Prod
      : Label.System_Mulesoft_Test;

    User currentUser = MTCUserUtil.currentUserObj;
    request.setEndpoint(
      'callout:' +
      mulesoftEndpoint +
      '/deliverables/' +
      deliverable.TruTesta_ID__c +
      '/download?username=' +
      currentUser.Username +
      '&X-CustomerId=' +
      deliverable.Account.TruTesta_ID__c
    );
    // String trutestaTest = 'callout:TruTesta_Sandbox/trutesta-proxy-services/proxies/client-deliverables/reports/';
    // trutestaTest + deliverable.Parent.TruTesta_ID__c +
    // '/deliverables/' + deliverable.TruTesta_ID__c + '/download?loggedInUserName=' + MTCUserUtil.currentUserObj.Username

    request.setMethod('GET');
    request.setHeader('Accept', '*/*');
    request.setHeader('Accept-Encoding', 'gzip, deflate, br');
    request.setHeader('Connection', 'keep-alive');
    // request.setHeader('X-CustomerId', deliverable.Account.TruTesta_ID__c);
    // request.setHeader('X-api-key', '{!$Credential.Password}');
    request.setHeader('client_id', '{!$Credential.Username}');
    request.setHeader('client_secret', '{!$Credential.Password}');

    if (Test.isRunningTest()) {
      response = new HttpResponse();
      response.setStatusCode(404);
    } else {
      response = http.send(request);
    }
    if (response.getStatusCode() == 200) {
      b64encDoc = EncodingUtil.base64Encode(response.getBodyAsBlob());
      if (response.getHeaderKeys().contains('Content-Disposition')) {
        documentName = response.getHeader('Content-Disposition');
        documentName = documentName.substringAfter('=');
        documentName = documentName.remove('"');
      } else {
        documentName = deliverable.Name;
      }
    } else {
      // throw new AuraHandledException('Unable to retrieve document');
      documentName = 'ErrorOccured.txt';
      b64encDoc = EncodingUtil.base64Encode(
        Blob.valueOf('The document requested was not found.')
      );
    }

    if (!String.isBlank(b64encDoc)) {
      result.put('document', b64encDoc);
      result.put('documentName', documentName);
      return result;
    } else {
      return new Map<String, String>();
    }
  }

  @testVisible
  private static String documentHost {
    get {
      return OrgUtil.isProduction()
        ? Label.MTC_System_DocumentDownload_URL
        : Label.MTC_System_DocumentDownload_Staging_URL;
    }
    private set;
  }
  @testVisible
  private static String documentHostAPIKey {
    get {
      return OrgUtil.isProduction()
        ? Label.MTC_System_DocumentDownload_APIKEY
        : Label.MTC_System_DocumentDownload_Staging_APIKEY;
    }
    private set;
  }

  @AuraEnabled(cacheable=false)
  public static String getDocDownloadEphemeralURL(
    Id reportId,
    Id deliverableId
  ) {
    String result = '';
    User currentUser = MTCUserUtil.currentUserObj;

    //check access
    List<Asset> deliverables = [
      SELECT
        Name,
        TruTesta_ID__c,
        Parent.Name,
        Parent.TruTesta_ID__c,
        Account.TruTesta_ID__c
      FROM Asset
      WHERE Id = :deliverableId AND ParentId = :reportId
    ];
    if (!deliverables.isEmpty()) {
      Asset deliverable = deliverables[0];

      String shared = EncodingUtil.base64decode(
          Label.MTC_System_DocumentDownload_AppID
        )
        .toString();

      String email = currentUser.Username;
      String deliverableTrutestaID = deliverable.TruTesta_ID__c;
      String customerTrutestaID = deliverable.Account.TruTesta_ID__c;

      Long littleLater = DateTime.now().getTime() + 15 * 1000;

      String toSign =
        'c=' +
        customerTrutestaID +
        '&k=' +
        documentHostAPIKey +
        '&un=' +
        email +
        '&id=' +
        deliverableTrutestaID +
        '&expires=' +
        littleLater;

      String toSignEncoded = EncodingUtil.base64Encode(Blob.valueOf(toSign));

      Blob digest = Crypto.generateDigest(
        'SHA-256',
        Blob.valueOf(shared + toSignEncoded + shared)
      );

      String encoded = EncodingUtil.base64Encode(digest);

      String URI = documentHost + deliverable.TruTesta_ID__c + '/download';

      result =
        '' +
        URI +
        '?p=' +
        EncodingUtil.urlEncode(toSignEncoded, 'UTF-8') +
        '&sig=' +
        EncodingUtil.urlEncode(encoded, 'UTF-8');
    }
    return result;
  }
}