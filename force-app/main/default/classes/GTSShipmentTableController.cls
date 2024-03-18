public with sharing class GTSShipmentTableController {
	@AuraEnabled(cacheable=true)
	public static String getShipments(String recordId) {
		List<GTS_Certificate__c> shipments = [
			SELECT
				Id,
				GTS_Job__c,
				Name,
				GTS_Commercial_Invoice__c,
				GTS_Status__c,
				GTS_Received_Date__c,
				GTS_Certificate_Reference__c,
				GTS_Date_Issued__c
			FROM GTS_Certificate__c
			WHERE GTS_Job__c = :recordId
			ORDER BY GTS_Date_Issued__c DESC
		];
		return JSON.serialize(shipments);
	}
}