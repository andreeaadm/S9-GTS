global class LightningForgotPasswordController {
    public LightningForgotPasswordController() {
    }
    
    @AuraEnabled
    public static String forgotPassword(String username, String checkEmailUrl) {
        try {
            if (!Site.isValidUsername(username)) {
                return Label.Site.invalid_email;
            }
            else{      
        		Forgot_Password_Log__c fpl = new Forgot_Password_Log__c();
        		fpl.Username_Entered__c = username;
        		fpl.Created_Date__c = system.now();
                Site.forgotPassword(username);
                insert fpl;
                ApexPages.PageReference checkEmailRef = new PageReference(checkEmailUrl);
                aura.redirect(checkEmailRef);
                return null;
            }
            
        } catch (Exception ex) {
            return ex.getMessage();
        }
    }
    
    @AuraEnabled
    global static String setExperienceId(String expId) {
        // Return null if there is no error, else it will return the error message
        try {
            if (expId != null) {
                Site.setExperienceId(expId);
            }
            return null;
        } catch (Exception ex) {
            return ex.getMessage();
        }
    }
}