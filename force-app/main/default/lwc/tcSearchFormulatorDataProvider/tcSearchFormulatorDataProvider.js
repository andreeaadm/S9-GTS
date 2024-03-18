const getFormulatorDatatableRows = (
  inputList,
  batchSize,
  batchNumber,
  tableColumns
) => {
  let rows = [];
  let maxTotalToReturn = batchSize * batchNumber;
  rows = inputList.slice(0, maxTotalToReturn);

  const datatableRows = [];
  rows.forEach((data) => {
    let rowCells = [
      { value: data.organizationName, styleClass: "organizationName" },
      { value: data?.address, styleClass: "address" },
      { value: data?.supplierAID, styleClass: "supplierAID" },
      {
        value: "SELECT",
        isAction: true,
        isButton: true,
        actionName: "customEvent",
        styleClass: "clickable",
        buttonVariant: "IntkBrandOneBtn"
      }
    ];
    for (let i = 0; i < tableColumns.length; i++) {
      rowCells[i].id = tableColumns[i].id;
      rowCells[i].columnLabel = tableColumns[i].label;
    }
    datatableRows.push({
      rowId: data.formulatorGUID,
      rowCells
    });
  });

  return datatableRows;
};

export { getFormulatorDatatableRows };