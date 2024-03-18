public without sharing  class iCare_GetSiteURL {
	@InvocableMethod(label='Get iCareSiteUrl' description='Returns the base URL for iCareSite')
	public static List<String> getAccountNames(List<ID> ids) {
		Id siteId = [SELECT Id FROM Site WHERE Name = 'iCare'].Id;
		SiteDetail siteDetail = [SELECT Id,SecureUrl FROM SiteDetail WHERE DurableId = :siteId];
		return new List<String> {siteDetail.SecureUrl};
	}
}