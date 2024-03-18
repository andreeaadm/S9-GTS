import { LightningElement, wire, track } from "lwc";
import getSupplierConformanceByMonth from "@salesforce/apex/TC_SupplierConformanceController.getSupplierConformanceByMonth";
import { label } from "c/labelService";

export default class TcSupplierConformance extends LightningElement {
  labels = label;
  title = this.labels.SUPPLIER_CONFORMANCE_TARGETS;
  selectedMonth = "";

  @wire(getSupplierConformanceByMonth, { selectedMonth: "$selectedMonth" })
  wireResponse;

  handleMonthChange(evt) {
    this.selectedMonth = evt.detail.value;
  }
}