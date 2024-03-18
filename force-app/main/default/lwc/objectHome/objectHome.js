import { LightningElement, api, track } from "lwc";

export default class ObjectHome extends LightningElement {
  @api title = "Object Home";
  @api btnLabel = "";
  @api btnTwoLabel = "";
  @api isLoading;
  @api get tableData() {
    return this._tableData;
  }
  @track selectedRowId = '';
  set tableData(value) {
    this._tableData = value;
    let selectedRowIds = [];
    if (this.tableData && this.tableData.rows) {
      for (let row of this.tableData.rows) {
        if (
          row.rowCells &&
          row.rowCells[0].isCheckbox &&
          row.rowCells[0].value == "true"
        ) {
          selectedRowIds.push(row.rowId);
        }
      }
      this.tempSelectedRowIds = selectedRowIds;
      this.selectedRowIds = selectedRowIds;
      this.selectedRowCount = selectedRowIds.length;
      this.updateSelectedRowIds();
      this.tableHeaderActionsVisible = selectedRowIds.length > 0 ? true : false;
    }
    if (this.selectedRowCount > 0) {
      if (this.selectedRowCount != this.tableData.rows.length) {
        this.selectedState = "indeterminate";
      } else {
        this.selectedState = "selected";
      }
    } else {
      this.selectedState = "unselected";
    }
  }
  @api tableHeaderActionsVisible = false;
  @api scrollAfterXPixels;
  @api actions = [];
  @api loadMoreMessage;
  @api allShown;
  @track selectedRowCount = 0;
  @track selectedRowIds = [];
  @track tempSelectedRowIds = [];
  // selectedState can be "unselected", "indeterminate" or "selected"
  // this will be used to drive the tableActions checkbox selected state
  @track selectedState = "unselected";
  @track orderBy;
  @track filterClass = "filters";

  rowIdTimeout;

  handleSortClick(evt) {
    // tell the parent to update orderBy, which should trigger an @wire to refresh table data
    // we combine the two event attributes together in order to prevent @wire from calling Apex twice
    let orderBy =
      evt.detail.colId +
      " " +
      (evt.detail.currentSortOrder == "DESC" ? "ASC" : "DESC");
    this.dispatchEvent(new CustomEvent("orderby", { detail: orderBy }));
  }

  handleViewMore(evt) {
    this.dispatchEvent(new CustomEvent("viewmore"));
  }

  handleBtnClick(evt) {
    this.dispatchEvent(
      new CustomEvent("btnclick", {
        detail: {
          label: evt.detail.label
        }
      })
    );
  }

  handleActionClick(evt) {
    this.dispatchEvent(
      new CustomEvent("actionclick", {
        detail: {
          label: evt.detail.label
        }
      })
    );
  }

  handleCheckboxChange(evt) {
    // update selectedRowIds
    // depending on whether we were selecting a checkbox, selecting the final unselected checkbox, or deselecting the last selected checkbox...
    // update the c-table-actions selectedState appropriately
    let tempSelectedRowIds = JSON.parse(
      JSON.stringify(this.tempSelectedRowIds)
    );
    if (evt.detail.checked) {
      tempSelectedRowIds.push(evt.detail.rowId);
      this.selectedRowCount++;
      this.tempSelectedRowIds = tempSelectedRowIds;
      this.updateSelectedRowIds(tempSelectedRowIds);
      this.tableHeaderActionsVisible = true;
      if (this.selectedRowCount != this.tableData.rows.length) {
        this.selectedState = "indeterminate";
      } else {
        this.selectedState = "selected";
      }
    } else {
      tempSelectedRowIds = tempSelectedRowIds.filter(function (
        value,
        index,
        arr
      ) {
        return value !== evt.detail.rowId;
      });
      this.selectedRowCount--;
      this.tempSelectedRowIds = tempSelectedRowIds;
      this.updateSelectedRowIds(tempSelectedRowIds);
      if (this.selectedRowCount != 0) {
        this.selectedState = "indeterminate";
      } else {
        this.tableHeaderActionsVisible = false;
        this.selectedState = "unselected";
        this.template.querySelector("c-datatable").uncheckHeader();
      }
    }
  }

  updateSelectedRowIds(selectedRowIds) {
    selectedRowIds = selectedRowIds ? selectedRowIds : this.selectedRowIds;
    window.clearTimeout(this.rowIdTimeout);
    this.rowIdTimeout = setTimeout(
      function () {
        this.selectedRowIds = selectedRowIds;
        this.dispatchEvent(
          new CustomEvent("selectedrowschange", {
            detail: {
              selectedRowIds: selectedRowIds
            }
          })
        );
      }.bind(this),
      100
    );
  }

  handleActionsCheckboxChange(evt) {
    // uncheck the datatable header checkbox before it's visible
    this.selectedState = evt.detail.checked ? "selected" : "unselected";
    this.handleHeaderCheckboxChange(evt);
    this.template.querySelector("c-datatable").uncheckHeader();
  }

  handleHeaderCheckboxChange(evt) {
    // handle the checking or unchecking of the table header checkbox
    if (evt.detail.checked) {
      this.template.querySelector("c-datatable").checkAll();
    } else if (evt.detail.checked === false) {
      this.template.querySelector("c-datatable").uncheckAll();
    }
  }

  openFilters() {
    this.filterClass = "filters active";
  }

  closeFilters() {
    this.filterClass = "filters";
  }

onCellClick(event) {
  this.selectedRowId = event.detail.rowId;
  if(this.selectedRowId) {
  const passCellClickedEvent = new CustomEvent('cellclicked', {
    detail:{isCellClicked:true,
            selectedRowId:this.selectedRowId} 
    });
    this.dispatchEvent(passCellClickedEvent);
}
  }
}