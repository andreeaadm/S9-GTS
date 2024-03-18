import { LightningElement, api } from "lwc";
import { label } from "c/labelService";

export default class TcSearchFormulatorsInput extends LightningElement {
  //PUBLIC PROPERTIES
  @api required;
  @api allowCreateFormulator;

  //TEMPLATE PROPERTIES
  labels = label;
  showSearchFormulator;
  showSelectedFormulator;
  selectedFormulatorName;

  //EVENT HANDLERS

  /**
   * call this public method to reset state.
   */
  @api
  reset() {
    this.showSearchFormulator = false;
    this.showSelectedFormulator = false;
    this.selectedFormulatorName = null;
  }

  /**
   * handles the user's request to search a Formulator
   */
  handleSearchFormulator() {
    this.showSearchFormulator = true;
  }

  /**
   * handles the user selecting a formulator record
   * @param {object} event - selectformulator custom event
   */
  handleSelectFormulator(event) {
    this.showSearchFormulator = false;
    this.showSelectedFormulator = true;
    this.selectedFormulatorName = event.detail.row.organizationName;
  }

  handleRemoveFormulator() {
    this.showSelectedFormulator = false;
    this.selectedFormulatorName = null;
    this.dispatchEvent(new CustomEvent("removeformulator"));
  }

  /**
   * handles the user successfully creating a formulator
   * @param {object} event - createdformulator custom event
   */
  handleCreatedFormulator(event) {
    this.showSearchFormulator = false;
    this.showSelectedFormulator = true;
    this.selectedFormulatorName = event.detail.Name;
  }

  /**
   * handles the user closing the formulator modal
   */
  handleCloseModal() {
    this.showSearchFormulator = false;
  }
}