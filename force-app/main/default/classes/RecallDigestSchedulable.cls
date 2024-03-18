/**
* @author Buddy Winter <buddy.winter@cloudshiftgroup.com>
* @date 2022-04-21
* @group CloudShiftGroup
* @description Schedulable class for generation of scheduled Recall Digest email for GMA HLSL portal users.
*
* Date              Author              Change Description
* -----------------------------------------------------------------------------------
* 21/04/2022        Buddy Winter        Created Class
*/
global without sharing class RecallDigestSchedulable implements Schedulable {

    global void execute(SchedulableContext sc){
        RecallDigestProcessor.generateEmails(System.today() - 7, System.today());
    }
}