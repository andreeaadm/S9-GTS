import { LightningElement, api, track } from 'lwc';

export default class Inputgroup extends LightningElement {
    @api label;
    @api multiSelect;
    @track errors;
    hasRendered = false;

    constructor() {
        super();
        this.template.addEventListener('change', this.handleChange.bind(this));
    }

    renderedCallback() {
        if (!this.hasRendered) {
            this.validateAttributes();
            this.hasRendered = true;
        }
    }

    validateAttributes() {
        const slot = this.template.querySelector('slot[name="content"]');
        let nodes = slot.assignedNodes();
        let inputs = [];
        for (let node of nodes) {
            if (typeof node !== 'undefined' && node.getType) {
                inputs.push(node);
            } else {
                inputs = node.querySelectorAll('c-input').length > 0 ? node.querySelectorAll('c-input') : node.querySelectorAll('c-tile');
            }
        }
        if (this.multiSelect) {
            this.validateMultiSelect(inputs);
        }
    }

    validateMultiSelect(inputs) {
        for (let input of inputs) {
            const type = input.getType();
            if (type !== 'Checkbox') {
                let e = 'Multi select mode only supports checkbox inputs';
                this.errors ? this.errors.push(e) : this.errors = [e];
                break;
            }
        };
    }

    handleChange(evt) {
        evt.stopPropagation();
        evt = this.multiSelect ? this.processMultiSelect(evt) : this.processSingleSelect(evt);
        const fieldId = evt.detail.fieldId ? evt.detail.fieldId : this.fieldId;
        const value = this.multiSelect ? evt.detail.value : evt.detail.label;
        this.dispatchEvent(new CustomEvent('change', { bubbles: true, detail: { fieldId: fieldId, value: value } }));
    }

    processSingleSelect(evt) {
        let slot = this.template.querySelector('slot[name="content"]');
        let nodes = slot.assignedNodes();
        let inputs = [];
        for (let node of nodes) {
            if (typeof node !== 'undefined' && node.getType) {
                inputs.push(node);
            } else {
                inputs = node.querySelectorAll('c-input').length > 0 ? node.querySelectorAll('c-input') : node.querySelectorAll('c-tile');
            }
        };
        for (let input of inputs) {
            let type = input.getType();
            if (type === 'Checkbox' || type === 'Radio') {
                input.processUncheck(evt.detail.label);
            }
        }
        return evt;
    }

    processMultiSelect(evt) {
        let inputs = this.findInputs();
        let concatValue = '';
        for (let input of inputs) {
            let type = input.getType();
            let checked = input.getChecked();
            let label = input.getLabel();
            if (type === 'Checkbox' && checked) {
                concatValue += label + ';';
            }
        };
        if (concatValue && concatValue.length) {
            evt.detail.value = concatValue.substring(0, concatValue.length - 1);
        }
        return evt;
    }

    findInputs() {
        let slot = this.template.querySelector('slot[name="content"]');
        let nodes = slot.assignedNodes();
        let inputs = [];
        for (let node of nodes) {
            if (typeof node !== 'undefined' && node.getType) {
                inputs.push(node);
            } else {
                inputs = node.querySelectorAll('c-input').length > 0 ? node.querySelectorAll('c-input') : node.querySelectorAll('c-tile');
            }
        };
        return inputs;
    }

}