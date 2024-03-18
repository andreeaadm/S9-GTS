import { LightningElement, api, track, wire } from 'lwc';
import getAllItemsForType from "@salesforce/apex/CMSController.getAllItemsForType";

export default class GmaAccordion extends LightningElement {

  @api managedContentType = "FAQ";
  @api titleFieldName = "Question";
  @api contentFieldName = "Answer";
  @api orderingFieldName = "Order";
  @track items;
  @track error;

  @api get topics() {
    return this._topics?.length > 0 ? this._topics : undefined;
  }
  set topics(value) {
    this._topics = value?.includes(",")
      ? value.split(/\s*,\s*/)
      : value?.length > 0
      ? [value.trim()]
      : [];
  }

  _topics = [];
  @wire(getAllItemsForType, {
    managedContentType: "$managedContentType",
    topics: "$_topics",
    itemsPerPage: null,
    pageNumber: null,
    language: null
  })
  wiredContent({ error, data }) {
    if (data) {
      let tempData = [].concat(JSON.parse(JSON.stringify(data.content.items)));
      tempData = this.processReturnData(tempData);
      this.items = tempData;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.items = undefined;
    }
  }

  processReturnData(items) {
    for (let item of items) {
      if (!item.contentNodes[this.orderingFieldName]) {
        item.contentNodes[this.orderingFieldName] = { value: "" };
      }
      item.contentNodes.title = {
        value: item.contentNodes[this.titleFieldName]
          ? item.contentNodes[this.titleFieldName].value
          : ""
      };
      item.contentNodes.content = {
        value: item.contentNodes[this.contentFieldName]
          ? item.contentNodes[this.contentFieldName].value
              .replaceAll("&lt;", "<")
              .replaceAll("&gt;", ">")
              .replaceAll("&amp;", "&")
              .replaceAll("&quot;", '"')
          : ""
      };
    }
    items.sort((a, b) =>
      this.advancedSort(a, b)
    );
    return items;
  }

  advancedSort(a, b) {
    let hasData = (a.contentNodes!=null && a.contentNodes!==undefined && b.contentNodes!=null && b.contentNodes!==undefined);
    let hasParams = (this !== undefined && this.orderingFieldName!==undefined);
    if (hasData && hasParams) {
      let el_a = parseFloat(a.contentNodes[this.orderingFieldName].value);
      let el_b = parseFloat(b.contentNodes[this.orderingFieldName].value);
      el_a = (el_a>0 ? el_a : 100);
      el_b = (el_b>0 ? el_b : 100);
      return (el_a > el_b ? 1 : -1);
    }

    return -1;
  }

    toggleActive(event){
        var index = event.currentTarget.dataset.headerindex;        
        this.template.querySelector('[data-containerindex="' +index+ '"]').className = this.template.querySelector('[data-containerindex="' +index+ '"]').className ? "" : "active";
        if(this.template.querySelector('[data-containerindex="' +index+ '"]').className == "active"){
            this.template.querySelector('[data-contentindex="' +index+ '"]').style.maxHeight = this.template.querySelector('[data-contentindex="' +index+ '"]').scrollHeight + "px";
            this.closeOtherSections(index);
        }else{
            this.template.querySelector('[data-contentindex="' +index+ '"]').style.maxHeight = 0;
        } 
    }

    closeOtherSections(index){
        for(var i=0;i<this.items.length;i++){
            if(i!=index){
                this.template.querySelector('[data-contentindex="' +i+ '"]').style.maxHeight = 0;
                this.template.querySelector('[data-containerindex="' +i+ '"]').className = "";
            }
        }
    }
}