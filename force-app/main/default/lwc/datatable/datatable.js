import { LightningElement, api, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { label } from "c/labelService";

export default class Datatable extends NavigationMixin(LightningElement) {
  @api isLoading = false;
  @api get scrollafterxpixels() {
    return this._scrollafterxpixels;
  }
  set scrollafterxpixels(value) {
    this._scrollafterxpixels = value;
  }
  @api get mode() {
    return this._mode;
  }
  set mode(value) {
    this._mode = value;
    if (this.isFixedColumn) {
      this.splitData();
    }
  }
  @api get mobEnabled() {
    return this._mobEnabled;
  }
  set mobEnabled(value) {
    this._mobEnabled = value;
    this.buildWrapperClass();
  }
  @api get tableCols() {
    return this._tableCols;
  }
  set tableCols(value) {
    this._tableCols = value;
    if (this.isFixedColumn) {
      this.splitData();
    }
  }
  @api get tableRows() {
    return this._tableRows;
  }
  set tableRows(value) {
    this._tableRows = value;
    if (this.isFixedColumn) {
      this.splitData();
    }
  }
  @api get tableHeaderActionsVisible() {
    return this._tableHeaderActionsVisible;
  }
  set tableHeaderActionsVisible(value) {
    this._tableHeaderActionsVisible = value;
    if (this.hasRendered) {
      this.updateTableHeaderActionsClass();
    }
  }
  @api get additionalClasses() {
    return this._additionalClasses;
  }
  set additionalClasses(value) {
    this._additionalClasses = value;
    if (this.hasRendered) {
      this.buildWrapperClass();
    }
  }
  @api
  title;
  @api
  allShown;
  @api
  loadMoreMessage;
  @api
  noResultsMessage = label ? label.NO_RESULTS_FOUND : "";
  @track
  wrapperClass = "";
  @track
  renderComplete = false;
  @track
  firstCol;
  @track
  firstColCells;
  @track
  rowSelected = false;

  _tableCols;
  _tableRows;
  _scrollafterxpixels;
  _mode = "standard";
  _mobEnabled = false;
  _tableHeaderActionsVisible = false;
  _additionalClasses;
  hasRendered = false;
  labels = label;

  get tableIsEmpty() {
    return !this.isLoading && (!this.tableRows || this.tableRows?.length == 0)
      ? true
      : false;
  }

  get isFixedHeader() {
    return this.mode === "fixed-header" ? true : false;
  }

  get isFixedColumn() {
    return this.mode === "fixed-column" ? true : false;
  }

  renderedCallback() {
    // We want to re-evaluate the height of tbody on every render
    this.buildWrapperClass();
    this.updateTableHeaderActionsClass();
    this.hasRendered = true;
  }

  splitData() {
    let tableCols = this.tableCols;
    let tableRows = this.tableRows;
    if (tableCols) {
      this.firstCol = this.tableCols[0];
    }
    if (tableRows) {
      let firstColCells = [];
      for (let row of tableRows) {
        firstColCells.push({
          rowId: row.rowId,
          rowCells: [row.rowCells[0]]
        });
      }
      this.firstColCells = firstColCells;
    }
  }

  buildWrapperClass() {
    let isScroll = this.calculateIsScroll();
    let wrapperClass = this.additionalClasses
      ? this.additionalClasses + " "
      : "";
    if (this.mode) {
      switch (this.mode) {
        case "standard":
          wrapperClass += "std";
          break;
        case "standard-vscroll":
          wrapperClass += "std vscroll";
          break;
        case "standard-hscroll":
          wrapperClass += "std hscroll";
          break;
        case "standard-vhscroll":
          wrapperClass += "std vscroll hscroll";
          break;
        case "fixed-header":
          wrapperClass += "fix-th-vscroll";
          break;
        case "fixed-column":
          wrapperClass += "fix-td1-hscroll";
          break;
      }
    }
    if (this.mobEnabled) {
      wrapperClass += " mob-listoutput";
    }
    if (isScroll) {
      wrapperClass += " vscroll-active";
    }
    this.wrapperClass = wrapperClass;
  }

  updateTableHeaderActionsClass() {
    if (this.isFixedHeader) {
      let headerTable = this.template.querySelector(".table-header table");
      let headerActions = this.template.querySelector(".header-actions");
      if (this.tableHeaderActionsVisible) {
        headerTable.classList.add("hidden");
        headerActions.classList.remove("hidden");
      } else {
        headerTable.classList.remove("hidden");
        headerActions.classList.add("hidden");
      }
    }
  }

  calculateIsScroll() {
    let isScroll = false;
    try {
      if (
        this.scrollafterxpixels &&
        (this.mode === "standard-vscroll" ||
          this.mode === "standard-vhscroll" ||
          this.mode === "fixed-header")
      ) {
        this.template
          .querySelector("div[data-id=overflow]")
          .style.setProperty("max-height", this.scrollafterxpixels + "px");

        //Get height of container
        let parent = this.template.querySelector("tbody");

        if (parent.clientHeight > parseInt(this.scrollafterxpixels)) {
          isScroll = true;
        }
      } else {
        this.template
          .querySelector("div[data-id=overflow]")
          .style.removeProperty("max-height");
      }
    } catch (e) {
      /* scroll container not found */ return false;
    }
    return isScroll;
  }

  rowLabelClick(evt) {
    this.doRowLabelNavigate(evt);
  }

  handleButtonClick(evt) {
    if (evt.detail.indexOne != "Load More") {
      this.handleCellClick(evt);
    } else {
      // Tell parent we want to view more rows
      this.dispatchEvent(new CustomEvent("viewmore"));
    }
  }

  checkboxChange(evt) {
    const label =
      evt.detail && evt.detail.label !== undefined
        ? evt.detail.label
        : evt.target.label;
    const checked =
      evt.detail && evt.detail.checked !== undefined
        ? evt.detail.checked
        : evt.target.checked;
    const rowId = evt.currentTarget.dataset.id;

    this.dispatchEvent(
      new CustomEvent("checkboxchange", {
        detail: {
          label: label,
          checked: checked,
          rowId: rowId
        }
      })
    );
  }

  headerCheckboxChange(evt) {
    evt.currentTarget.indeterminate = false;
    const label =
      evt.detail && evt.detail.label !== undefined
        ? evt.detail.label
        : evt.target.label;
    const checked =
      evt.detail && evt.detail.checked !== undefined
        ? evt.detail.checked
        : evt.target.checked;

    this.dispatchEvent(
      new CustomEvent("headercheckboxchange", {
        detail: {
          label: label,
          checked: checked
        }
      })
    );
  }

  selectListChange(evt) {
    this.dispatchEvent(
      new CustomEvent("selectlistchange", {
        bubbles: true,
        detail: {
          label: evt.detail.label,
          value: evt.detail.value,
          fieldId: evt.detail.fieldId
        }
      })
    );
  }

  doRowLabelNavigate(evt) {
    let clickedRowIndex = evt.currentTarget.dataset.row;
    let row = this.tableRows[clickedRowIndex];
    if (row.target) {
      this[NavigationMixin.GenerateUrl](row.navMixinPageRef).then((url) =>
        window.open(url, row.target)
      );
    } else {
      this[NavigationMixin.Navigate](row.navMixinPageRef);
    }
  }

  handleCellClick(evt) {
    let clickedRowIndex;
    let clickedCellIndex;

    if (
      evt.detail.indexOne !== undefined &&
      evt.detail.indexOne !== null &&
      evt.detail.indexTwo !== undefined &&
      evt.detail.indexTwo !== null
    ) {
      clickedRowIndex = evt.detail.indexOne;
      clickedCellIndex = evt.detail.indexTwo;
    } else {
      clickedRowIndex = evt.currentTarget.dataset.row;
      clickedCellIndex = evt.currentTarget.dataset.cell;
    }
    let row = this.tableRows[clickedRowIndex];
    let cell = row.rowCells[clickedCellIndex];
    
    if (cell.actionName === "customEvent") {
      this.dispatchEvent(
        new CustomEvent("cellclick", {
          detail: {
            rowId: row.rowId,
            rowLabel: row.rowLabel,
            actionName: cell.actionName,
            value: cell.value
          }
        })
      );
    } else if (cell.actionName === "selectList") {
    } else if (cell.navMixinPageRef) {
      if (cell.target) {
        this[NavigationMixin.GenerateUrl](cell.navMixinPageRef).then((url) =>
          window.open(url, cell.target)
        );
      } else {
        this[NavigationMixin.Navigate](cell.navMixinPageRef);
      }
    }
  }

  handleSortClick(evt) {
    this.dispatchEvent(
      new CustomEvent("sortclick", {
        detail: {
          colId: evt.currentTarget.dataset.id,
          currentSortOrder: evt.currentTarget.dataset.sort
        }
      })
    );
  }

  @api checkAll() {
    let table = this.template.querySelector(".main-table");
    for (let i = 0; i < table.rows.length; i++) {
      let firstCol = table.rows[i].cells[0];
      let checkbox = firstCol.querySelector("c-checkbox");
      if (!checkbox.getChecked()) {
        checkbox.click();
      }
    }
  }

  @api uncheckAll() {
    let table = this.template.querySelector(".main-table");
    for (let i = 0; i < table.rows.length; i++) {
      let firstCol = table.rows[i].cells[0];
      let checkbox = firstCol.querySelector("c-checkbox");
      if (checkbox.getChecked()) {
        checkbox.uncheck(false);
      }
    }
  }

  @api uncheckHeader() {
    let checkbox = this.template.querySelector(".table-header c-checkbox");
    checkbox.uncheck();
  }
}