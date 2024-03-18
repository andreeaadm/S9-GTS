/*******************************************************************************************
 * @name         GTSJobLifecycle
 * @author       Globant
 * @description  LWC Controller to get the information for Contacts
 * @date         12-March-2024
 *******************************************************************************************/
public without sharing class GTSJobRequestContactInfo {
	/**
	 * @description Method to get contact information
	 * @param accountId
	 * @param contactId
	 *
	 * @return
	 */
	@AuraEnabled
	public static Contact getContactInfo(String accountId, String contactId){
		Contact contact;
		String runningUserId = UserInfo.getUserId();

		List<AccountShare> accountShares = [SELECT Id FROM AccountShare WHERE AccountId =:accountId AND UserOrGroupId = :runningUserId WITH SYSTEM_MODE ];
		User userRecord = [SELECT Id, AccountId FROM User WHERE Id =: runningUserId WITH SYSTEM_MODE ];

		if(!accountShares.isEmpty() || accountId == userRecord.AccountId){
			contact = [SELECT Id,Email, Phone, MailingCity, MailingCountryCode, MailingPostalCode, MailingStreet, MailingStateCode FROM Contact WHERE Id = :contactId AND AccountId = :accountId  WITH SYSTEM_MODE LIMIT 1];
		}
		return contact;
	}

}