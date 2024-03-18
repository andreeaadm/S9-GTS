import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class Breadcrumb extends NavigationMixin(LightningElement) {
    /* crumbs is an array of objects. Each crumb should follow this format. action is optional (i.e. you can have a crumb that isn't clickable).
        [
            {
                id: 0,
                label: "Example crumb",
                action: {
                    type: "custom" | "navmixin" | "url",
                    detail: "event name" | { page reference object } | "destination url"
                }
            }
        ]
    */
    @api get crumbs() {
        return this._crumbs;
    }
    set crumbs(value) {
        // work through the new list of crumbs and if crumb ids haven't been specified, use label instead
        value = value.map(crumb =>
            crumb.id === undefined || crumb.id === "" ? { ...crumb, id: crumb.label } : crumb
        );
        this._crumbs = value;
    }
    _crumbs;

    handleClick(evt) {
        evt.stopPropagation();
        let index = evt.currentTarget.dataset.crumb;
        let crumb = this.crumbs[index];
        if(crumb.action && crumb.action.type) {
            switch(crumb.action.type) {
                case "custom":
                    this.dispatchEvent(new CustomEvent('click', { detail: { action: crumb.action.detail } }));
                    break;
                case "navmixin":
                    this[NavigationMixin.Navigate](crumb.action.detail);
                    break;
                case "url":
                    this[NavigationMixin.Navigate]( {
                        type: 'standard__webPage',
                        attributes: {
                            url: crumb.action.detail
                        }
                    });
                    break;
                default:
                    // if no crumb action type was specified, default to firing a CustomEvent
                    if(crumb.action.detail) {
                        this.dispatchEvent(new CustomEvent('click', { detail: { action: crumb.action.detail } }));
                    }
                    break;
            }
        }
    }

}