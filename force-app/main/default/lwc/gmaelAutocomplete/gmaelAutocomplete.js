import { LightningElement, api } from 'lwc';

export default class GmaelAutocomplete extends LightningElement {

    @api values;
    @api label = '';
    @api name = '';
    @api value = '';
    @api defaultValue = '';
    @api required;
    @api placeholder = '';
    @api disabled = false;
    initialized = false;
    requiredMsg = false;
    selectedKey = '';

    renderedCallback() {

        if (this.initialized) return;

        this.initialized = true;
        let listId = this.template.querySelector('datalist').id;
        this.template.querySelector("input").setAttribute("list", listId);

        this.setDefaultValue(this.values, this.defaultValue);
    }

    @api setDefaultValue(values, defaultValue) {

        if (defaultValue) {

            this.values = values;
            this.value = values.filter(function(item) { return item.key === defaultValue; })[0]?.value;
        }
    }

    handleChange(evt) {

        let _this = this;
        _this.value = evt?.target?.value?.trim();
        _this.selectedKey = _this.values.filter(function(item) { return item.value === _this.value; })[0]?.key;
        this.dispatchEvent(new CustomEvent('autochange', { bubbles: false, detail: { value: _this.value, key: _this.selectedKey, target: _this.name } }));
        this.handleBlur(evt);
    }

    @api handleBlur(evt) {

        if (this.required) {
            
            this.requiredMsg = !this.selectedKey ? true : false;
            if (this.requiredMsg) {

                this.template.querySelector('.custom-autocomplete').classList.add('req-field');
            } else {
                
                this.template.querySelector('.custom-autocomplete').classList.remove('req-field');
            }
        }
    }

    @api resetAutoComplete() {
        
        this.value = '';
        this.requiredMsg = false;
        this.template.querySelector('.custom-autocomplete').classList.remove('req-field');
    }

    @api fireValidation() {

        if (this.value !== '') {
            
            this.template.querySelector(".custom-autocomplete").classList.remove('custom-input');
        } else {
            
            this.template.querySelector(".custom-autocomplete").classList.add('custom-input');
        }
    }
}