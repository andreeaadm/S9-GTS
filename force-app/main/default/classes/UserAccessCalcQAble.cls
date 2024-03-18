public with sharing class UserAccessCalcQAble implements Queueable {
  private Map<Id, User> users = new Map<Id, User>();
  private Map<Id, User> usersLeft = new Map<Id, User>();
  public UserAccessCalcQAble(Map<Id, User> usersToEvaluate) {
    usersLeft = usersToEvaluate.deepClone();
    Integer count = 0;
    for (Id rId : usersLeft.keySet()) {
      count += 1;
      if (count < 200) {
        users.put(rId, usersLeft.get(rId));
        usersLeft.remove(rId);
      } else {
        break;
      }
    }
  }
  public void execute(QueueableContext context) {
    UserAccessUtil.calculateAccess(users);
    if (!usersLeft.isEmpty()) {
      System.enqueueJob(new UserAccessCalcQAble(usersLeft));
    }
  }
}