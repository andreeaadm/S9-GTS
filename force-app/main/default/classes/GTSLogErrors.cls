public with sharing class GTSLogErrors {

	public static void logDatabaseOperationErrors(List<Database.SaveResult> saveResults){
		for (Database.SaveResult saveResult : saveResults) {
			if (!saveResult.isSuccess()) {
				for (Database.Error err : saveResult.getErrors()) {
					System.debug('The following error has occurred.');
					System.debug(err.getStatusCode() + ': ' + err.getMessage());
				}
			}
		}
	}
	public static void logDatabaseOperationErrors(List<Database.DeleteResult> deleteResults){
		for (Database.DeleteResult deleteResult : deleteResults) {
			if (!deleteResult.isSuccess()) {
				for (Database.Error err : deleteResult.getErrors()) {
					System.debug('The following error has occurred.');
					System.debug(err.getStatusCode() + ': ' + err.getMessage());
				}
			}
		}
	}

}