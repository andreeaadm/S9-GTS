import { LightningElement } from 'lwc';
import { label } from 'c/labelService';

export default class TcAddProduct extends LightningElement {
	//TEMPLATE PROPERTIES
	labels = label;
	selectedFormulatorName;
	sourceValue = '0'; // Default to Include crowd sourced (0) Then 2, or 3.

	//INTERNAL PROPERTIES
	_requestedSearch;
	_hasFormValues;

	//GETTERS & SETTERS
	/**
   * @returns select list options for the source
   */
	get sourceOptions() {
		return [
			{ label: this.labels.TC_PRODUCTS_SOURCE_CROWD, value: '0' },
			{ label: this.labels.TC_PRODUCTS_SOURCE_ZDHC, value: '2' },
			{ label: this.labels.TC_PRODUCTS_SOURCE_OWN, value: '3' }
		];
	}

	/**
   * @returns true if the user hasn't filled any form fields
   */
	get searchDisabled() {
		return !this._hasFormValues;
	}

	//EVENT HANDLERS
	/**
   * handles the user requesting to search ZDHC products
   */
	handleSearch() {
		this._processSearchRequest();
	}

	/**
   * handle input onchange
   */
	handleChange() {
		this._getInputValues();
	}

	/**
   * handles the user reseting the form fields
   */
	handleResetForm() {
		this._requestedSearch = false;
		this.template.querySelector('c-tc-search-formulators-input').reset();
		this._resetInputValues();
		this.dispatchEvent(new CustomEvent('reset'));
	}

	/**
   * handles the user selecting a formulator record
   * @param {object} event - selectformulator custom event
   */
	handleSelectFormulator(event) {
		event.stopPropagation();
		this.selectedFormulatorName = event.detail.row.organizationName;
		this._getInputValues();
	}
	/**
   * handles the user clearing the selected formulator
   * @param {object} event - removeformulator custom event
   */
	handleRemoveFormulator(event) {
		event.stopPropagation();
		this.selectedFormulatorName = null;
		this.showSelectedFormulator = false;
		this._getInputValues();
	}

	//INTERNAL FUNCTIONS
	/**
   * processes the user's request to search the ZDHC / Salesforce product database
   */
	_processSearchRequest() {
		this._requestedSearch = true;
		let queryParameters = this._getInputValues();
		if (this._hasFormValues) {
			this.dispatchEvent(
				new CustomEvent('search', {
					detail: queryParameters
				})
			);
		}
	}

	/**
   * retrieves the input field values from the UI and builds the query params object
   * @returns an object containing query parameter key value pairs
   */
	_getInputValues() {
		let queryParameters = {};
		this._hasFormValues = false;
		this.template.querySelectorAll('c-input').forEach((el) => {
			queryParameters[el.fieldId] = el.value;
			if (el.value && el.value.length > 0 && el.fieldId !== 'Source') {
				this._hasFormValues = true;
			}
		});
		if (this.selectedFormulatorName && this.selectedFormulatorName.length > 0) {
			queryParameters.FormulatorName = this.selectedFormulatorName;
			this._hasFormValues = true;
		}
		return queryParameters;
	}

	/**
   * resets the form values
   */
	_resetInputValues() {
		this.template.querySelectorAll('c-input').forEach((el) => {
			if (el.fieldId === 'Source') {
				el.value = '0';
			} else {
				el.value = null;
			}
		});

		this._hasFormValues = false;
		this.showSelectedFormulator = false;
		this.selectedFormulatorName = null;
	}
}