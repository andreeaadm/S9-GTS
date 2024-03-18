public with sharing class iCare_BuyerController {
	@AuraEnabled(cacheable=true)
	public static String getBuyers(String accountId) {

		List<icare_Associated_Buyer_Program__c> associatedBuyerPrograms = getAssociatedBuyerProgramsByAccountId(accountId);
		List<BuyerWrapper> buyerWrappers = new List<iCare_BuyerController.BuyerWrapper>();
		for (icare_Associated_Buyer_Program__c associatedBuyerProgram : associatedBuyerPrograms) {
			buyerWrappers.add(new BuyerWrapper(associatedBuyerProgram.iCare_Buyer_Program__c, associatedBuyerProgram.iCare_Buyer_Program__r.Name, associatedBuyerProgram.iCare_Buyer_Program__r.iCare_Interlink_Buyer_Code__c));
		}
		return JSON.serialize(buyerWrappers);
	}

	@AuraEnabled(cacheable=true)
	public static String getFrequentBuyers(String accountId) {

		set<Id> buyerProgramIdSet = new set<Id>();
		list<BuyerWrapper> buyerWrapperList = new list<BuyerWrapper>();
		for(icare_Associated_Buyer_Program__c objAssociatedBuyer : [SELECT iCare_Buyer_Program__c FROM icare_Associated_Buyer_Program__c WHERE iCare_Supplier__c =: accountId]){
			buyerProgramIdSet.add(objAssociatedBuyer.iCare_Buyer_Program__c);
		}

		for(AggregateResult jobReq : [SELECT iCare_Buyer_Program__c buyerProgramId, iCare_Buyer_Program__r.Name buyerProgramName, COUNT(Id) FROM icare_Job_Request__c WHERE iCare_Buyer_Program__c != NULL AND iCare_Buyer_Program__c IN : buyerProgramIdSet
										GROUP BY iCare_Buyer_Program__c, iCare_Buyer_Program__r.Name ORDER BY COUNT_DISTINCT(Id) DESC 
										LIMIT 5]){
										
										BuyerWrapper buyerWrapper = new BuyerWrapper((Id)jobReq.get('buyerProgramId'), (String)jobReq.get('buyerProgramName'), null);
										buyerWrapperList.add(buyerWrapper);
		}
		return JSON.serialize(buyerWrapperList);
	}

	private static List<icare_Associated_Buyer_Program__c> getAssociatedBuyerProgramsByAccountId(String accountId) {
		return [
			Select Id,
				iCare_Buyer_Program__c,
				iCare_Buyer_Program__r.Name,
				iCare_Buyer_Program__r.iCare_Interlink_Buyer_Code__c
			FROM icare_Associated_Buyer_Program__c
			WHERE iCare_Supplier__c = :accountId
			ORDER BY iCare_Buyer_Program__r.Name
		];
	}

	private static List<iCare_Job__c> getJobRequestByAccountId(String accountId) {
		return [
			SELECT Id,
				iCare_Buyer_Program__c,
				iCare_Buyer_Program__r.Name,
				iCare_Buyer_Program__r.iCare_Interlink_Buyer_Code__c
			FROM iCare_Job__c
			WHERE iCare_Supplier__c = :accountId
		];
	}

	private class BuyerWrapper {
		private String id;
		private String buyerName;
		private String interlinkCode;

		private BuyerWrapper(String id, String buyerName, String interlinkCode) { //, String interlinkCode
			this.id = id;
			this.buyerName = buyerName;
			this.interlinkCode = (interlinkCode != null) ? interlinkCode : '';
		}
	}
}