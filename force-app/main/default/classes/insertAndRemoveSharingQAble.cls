public without sharing class insertAndRemoveSharingQAble implements Queueable {
  private List<Brand_Supplier_Connection__Share> connsToInsert;
  private List<Brand_Supplier_Connection__Share> connsToDelete;
  private List<AccountShare> acctsToInsert;
  private List<AccountShare> acctsToDelete;

  public insertAndRemoveSharingQAble(
    List<Brand_Supplier_Connection__Share> connsToInsert,
    List<Brand_Supplier_Connection__Share> connsToDelete,
    List<AccountShare> acctsToInsert,
    List<AccountShare> acctsToDelete
  ) {
    this.connsToInsert = connsToInsert;
    this.connsToDelete = connsToDelete;
    this.acctsToInsert = acctsToInsert;
    this.acctsToDelete = acctsToDelete;
  }

  // inserts and deletes appropriate records
  // delete is first to allow a recalc where all a User's shares are removed before being added back
  public void execute(QueueableContext qc) {
    if (this.connsToDelete != null) {
      Database.delete(this.connsToDelete, false);
    }

    if (this.acctsToDelete != null) {
      Database.delete(this.acctsToDelete, false);
    }

    if (this.connsToInsert != null) {
      Database.insert(this.connsToInsert, false);
    }

    if (this.acctsToInsert != null) {
      Database.insert(this.acctsToInsert, false);
    }
  }
}