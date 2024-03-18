public class PicklistController {
	public class PicklistWrapper{
		@AuraEnabled public String picklistValue;
        @AuraEnabled public String picklistLabel;

	}

    @AuraEnabled(cacheable=true)
    Public static List<PicklistWrapper> getDependentPicklistValues(String objectName, String dependentField, String controllingFieldValue) {
		 
        Map<String,List<PicklistWrapper>> dependentPicklistValues = getDependentValues(objectName, dependentField);
        return dependentPicklistValues.get(controllingFieldValue);
    }

    public static Map<String, List<PicklistWrapper>> getDependentValues(String objectName, String dependentField){
        Schema.SObjectType sObjectSchema = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeFieldResult depend = sObjectSchema.getDescribe().fields.getMap().get(dependentField).getDescribe();
        Schema.sObjectField theField = depend.getSObjectField();
        Schema.sObjectField ctrlField = depend.getController();		
		List<Schema.PicklistEntry> contrEntries = ctrlField.getDescribe().getPicklistValues();
		List<PicklistEntryWrapper> depEntries = PicklistController.wrapPicklistEntries(theField.getDescribe().getPicklistValues());
		Map<String, List<PicklistWrapper>> objResults = new Map<String, List<PicklistWrapper>>();
		List<String> controllingValues = new List<String>();

		for (Schema.PicklistEntry ple : contrEntries) {
			String label = ple.getValue();
			objResults.put(label, new List<PicklistWrapper>());
			controllingValues.add(label);
		}

		for (PicklistEntryWrapper plew : depEntries) {
			String label = plew.label;
			String value = plew.value;
			String validForBits = base64ToBits(plew.validFor);
			for (Integer i = 0; i < validForBits.length(); i++) {
				String bit = validForBits.mid(i, 1);
				if (bit == '1') {
					PicklistWrapper pl = new PicklistWrapper();
					pl.picklistLabel = label;
					pl.picklistValue = value;
					objResults.get(controllingValues.get(i)).add(pl);
				}
			}
		}

		return objResults;
	}

	public static String decimalToBinary(Integer val) {
		String bits = '';
		while (val > 0) {
			Integer remainder = Math.mod(val, 2);
			val = Integer.valueOf(Math.floor(val / 2));
			bits = String.valueOf(remainder) + bits;
		}
		return bits;
	}

	public static String base64ToBits(String validFor) {
		if (String.isEmpty(validFor)) {return '';}

		String validForBits = '';

		for (Integer i = 0; i < validFor.length(); i++) {
			String thisChar = validFor.mid(i, 1);
			Integer val = BASE64CHARS.indexOf(thisChar);
			String bits = decimalToBinary(val).leftPad(6, '0');
			validForBits += bits;
		}

		return validForBits;
	}


	private static final String BASE64CHARS = '' +
			'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
			'abcdefghijklmnopqrstuvwxyz' +
			'0123456789+/';


	private static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> pLEs) {
		return (List<PicklistEntryWrapper>)
			JSON.deserialize(JSON.serialize(pLEs), List<PicklistEntryWrapper>.class);
	}

	public class PicklistEntryWrapper {
		public String active {get; set;}
		public String defaultValue {get; set;}
		public String label {get; set;}
		public String value {get; set;}
		public String validFor {get; set;}
	}
}