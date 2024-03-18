public class MTCVFLoginFlowController {
  public Boolean acceptedTerms { get; set; }
  public String error { get; set; }

  public MTCVFLoginFlowController() {
    this.acceptedTerms = false;
  }

  public PageReference doInit() {
    User u = [
      SELECT Id, Date_MTC_Terms_Accepted__c
      FROM User
      WHERE Id = :UserInfo.getUserId()
      LIMIT 1
    ];
    // Ceck if user previously accepted terms
    if (
      u.Date_MTC_Terms_Accepted__c != null &&
      u.Date_MTC_Terms_Accepted__c <= DateTime.now()
    ) {
      // Set checkbox which triggers Flow to update Notifications Cutoff field afer a 2 hour delay
      u.User_logged_in_to_MTC__c = true;
      update u;
      //finish the login flow and send you the default homepage
      return Auth.SessionManagement.finishLoginFlow();
    } else {
      return null;
    }
  }

  public PageReference FinishLoginFlowHome() {
    this.error = '';
    if (this.acceptedTerms) {
      try {
        // Set checkbox which triggers Flow to update Notifications Cutoff field afer a 2 hour delay
        // Also set Date MTC Terms Accepted so that the user doesn't get asked next time they log in
        User u = new User(
          Id = UserInfo.getUserId(),
          Date_MTC_Terms_Accepted__c = DateTime.now(),
          User_logged_in_to_MTC__c = true
        );
        update u;
        //finish the login flow and send you the default homepage
        return Auth.SessionManagement.finishLoginFlow();
      } catch (Exception e) {
        this.error = 'Something has gone wrong, please contact support';
        return null;
      }
    } else {
      this.error = 'You must accept the terms & conditions and privacy policy';
      return null;
    }
  }
}