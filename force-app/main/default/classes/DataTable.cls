public with sharing class DataTable {
  public class Table {
    @AuraEnabled
    public List<Column> columns;
    @AuraEnabled
    public List<Row> rows;
    @AuraEnabled
    public String title;

    public Table(List<Column> columns, List<Row> rows, String title) {
      this.columns = columns;
      this.rows = rows;
      this.title = title;
    }
    public Table(List<Column> columns, List<Row> rows) {
      this.columns = columns;
      this.rows = rows;
    }
    public Table() {
      this.columns = new List<Column>();
      this.rows = new List<Row>();
    }
  }

  public class Column {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String label;
    @AuraEnabled
    public Boolean isCheckbox;
    @AuraEnabled
    public String sortOrder;
    @AuraEnabled
    public String thClass;
    @AuraEnabled
    public Boolean isSortable;

    public Column(String id, String label) {
      this.id = id;
      this.label = label;
      this.isCheckbox = false;
      this.sortOrder = null;
      this.thClass = null;
      this.isSortable = false;
    }

    public Column(String id, Boolean isCheckbox) {
      this.id = id;
      this.label = null;
      this.isCheckbox = isCheckbox;
      this.sortOrder = null;
      this.thClass = null;
      this.isSortable = false;
    }

    public Column(String id, String label, String sortOrder) {
      this.id = id;
      this.label = label;
      this.isCheckbox = false;
      this.sortOrder = sortOrder;
      this.thClass = sortOrder == ''
        ? 'sortable'
        : sortOrder == 'ASC' ? 'sortable sorted-asc' : 'sortable sorted-desc';
      this.isSortable = true;
    }

    public Column(String id, String label, Boolean isCheckbox) {
      this.id = id;
      this.label = label;
      this.isCheckbox = isCheckbox;
      this.sortOrder = null;
      this.thClass = null;
      this.isSortable = false;
    }
  }

  public class Row {
    @AuraEnabled
    public String rowId;
    @AuraEnabled
    public String rowLabel;
    @AuraEnabled
    public List<Cell> rowCells;

    public Row(String rowid, List<Cell> rowcells) {
      this.rowId = rowid;
      this.rowCells = rowcells;
    }

    public Row(String rowid, String rowLabel, List<Cell> rowcells) {
      this.rowId = rowid;
      this.rowLabel = rowLabel;
      this.rowCells = rowcells;
    }
  }

  public class Cell {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String value;
    @AuraEnabled
    public Map<String, Object> navMixinPageRef;
    @AuraEnabled
    public Boolean isAction;
    @AuraEnabled
    public Boolean isButton;
    @AuraEnabled
    public Boolean isLink;
    @AuraEnabled
    public String actionType;
    @AuraEnabled
    public String actionName;
    @AuraEnabled
    public String buttonVariant;
    @AuraEnabled
    public Boolean isCheckbox;
    @AuraEnabled
    public Boolean isSelectList;
    @AuraEnabled
    public Object selectListOptions;
    @AuraEnabled
    public String columnLabel;
    @AuraEnabled
    public Boolean disabled;
    @AuraEnabled
    public String styleClass;

    public Cell(
      String id,
      String value,
      Map<String, Object> navMixinPageRef,
      Boolean isAction,
      Boolean isButton,
      Boolean isLink,
      String actionType,
      String actionName,
      String buttonVariant,
      String columnLabel,
      Boolean disabled,
      String styleClass
    ) {
      this.id = id;
      this.value = value;
      this.navMixinPageRef = navMixinPageRef;
      this.isAction = isAction;
      this.isButton = isButton;
      this.isLink = isLink;
      this.actionType = actionType;
      this.actionName = actionName;
      this.buttonVariant = buttonVariant;
      this.columnLabel = columnLabel;
      this.disabled = disabled;
      this.styleClass = String.format(
        '{0} {1}',
        new List<String>{
          this.isAction ? 'clickable' : '',
          styleClass != null ? styleClass : ''
        }
      );
      this.styleClass = this.styleClass.trim();
    }

    public Cell(
      String id,
      String value,
      Map<String, Object> navMixinPageRef,
      Boolean isAction,
      Boolean isButton,
      Boolean isLink,
      String actionType,
      String actionName,
      String buttonVariant,
      String columnLabel,
      Boolean disabled
    ) {
      this.id = id;
      this.value = value;
      this.navMixinPageRef = navMixinPageRef;
      this.isAction = isAction;
      this.isButton = isButton;
      this.isLink = isLink;
      this.actionType = actionType;
      this.actionName = actionName;
      this.buttonVariant = buttonVariant;
      this.columnLabel = columnLabel;
      this.disabled = disabled;
      this.styleClass = isAction ? 'clickable' : '';
    }

    public Cell(
      String id,
      String value,
      Map<String, Object> navMixinPageRef,
      Boolean isAction,
      Boolean isButton,
      Boolean isLink,
      String actionType,
      String actionName,
      String buttonVariant,
      String columnLabel
    ) {
      this.id = id;
      this.value = value;
      this.navMixinPageRef = navMixinPageRef;
      this.isAction = isAction;
      this.isButton = isButton;
      this.isLink = isLink;
      this.actionType = actionType;
      this.actionName = actionName;
      this.buttonVariant = buttonVariant;
      this.columnLabel = columnLabel;
      this.disabled = false;
      this.styleClass = isAction ? 'clickable' : '';
    }

    public Cell(
      String id,
      String value,
      Boolean isCheckbox,
      Boolean isSelectList,
      Object selectListOptions,
      String columnLabel
    ) {
      this.id = id;
      this.value = value;
      this.isAction = false;
      this.isCheckbox = isCheckbox;
      this.isSelectList = isSelectList;
      this.selectListOptions = selectListOptions;
      this.columnLabel = columnLabel;
      this.disabled = false;
    }

    public Cell(
      String id,
      String value,
      Boolean isAction,
      String buttonVariant,
      String columnLabel
    ) {
      this.id = id;
      this.value = value;
      this.isAction = isAction;
      this.buttonVariant = buttonVariant;
      this.columnLabel = columnLabel;
      this.disabled = false;
      this.styleClass = isAction ? 'clickable' : '';
    }

    public Cell(
      String id,
      String value,
      String columnLabel,
      String styleClass
    ) {
      this.id = id;
      this.value = value;
      this.columnLabel = columnLabel;
      this.disabled = false;
      this.styleClass = styleClass;
    }

    public Cell(String id, String value, String columnLabel) {
      this.id = id;
      this.value = value;
      this.columnLabel = columnLabel;
      this.disabled = false;
    }
  }
}