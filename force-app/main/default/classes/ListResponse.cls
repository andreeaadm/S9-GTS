public with sharing class ListResponse {
    @AuraEnabled
    public DataTable.Table table;
    @AuraEnabled
    public Integer totalRows;
    public ListResponse(DataTable.Table table, Integer totalRows) {
        this.table = table;
        this.totalRows = totalRows;
    }
}