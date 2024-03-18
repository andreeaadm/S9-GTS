import { LightningElement, api, track } from "lwc";
import { nanoid } from "c/nanoid";
import {
  POLARAREA_CHART_TYPE,
  RADAR_CHART_TYPE,
  PIE_CHART_TYPE,
  DOUGHNUT_CHART_TYPE
} from "c/constants";
import getChartData from "@salesforce/apex/ChartBuilderController.getChartData";
import getChartOptions from "@salesforce/apex/ChartBuilderController.getChartOptions";
import getSupplierLocationsList from "@salesforce/apex/TC_InventoryConformancePercentagePie.getSupplierLocationsList";
import getSupplierTypeList from "@salesforce/apex/TC_InventoryConformancePercentagePie.getSupplierTypeList";
import getInventoryTypeList from "@salesforce/apex/TC_InventoryConformancePercentagePie.getInventoryTypeList";
import getConformanceTypeList from "@salesforce/apex/TC_InventoryConformancePercentagePie.getConformanceTypeList";
import getClassificationList from "@salesforce/apex/TC_InventoryConformancePercentagePie.getClassificationList";
import isSupplierUser from "@salesforce/apex/TC_InventoryConformancePercentagePie.isSupplierUser";
import { label } from "c/labelService";


const RADIAL_TYPE = [POLARAREA_CHART_TYPE, RADAR_CHART_TYPE];
const CIRCULAR_TYPE = [DOUGHNUT_CHART_TYPE, PIE_CHART_TYPE];
const DIMENSIONABLE_TYPES = [...CIRCULAR_TYPE, ...RADIAL_TYPE];

const isObject = (obj) => {
  return Object.prototype.toString.call(obj) === "[object Object]";
};
export default class ChartBuilder extends LightningElement {
  labels = label;
  selectedLocation = null;
  showLocationDiv = true;
  showSuppTypeDiv = true;
  showInvTypeDiv = true;

  isSupplierUser = false;
  disableclassfInput = true;

  @api
  get containerClass() {
    return `${this._containerClass} ${this._flexipageRegionWidth}`;
  }
  set containerClass(v) {
    this._containerClass = v;
  }

  _flexipageRegionWidth;
  @api
  get flexipageRegionWidth() {
    return this._flexipageRegionWidth;
  }
  set flexipageRegionWidth(v) {
    this._flexipageRegionWidth = v;
  }

  @api
  recordId;

  _title;
  @api
  get title() {
    return this._title;
  }
  set title(v) {
    if (v?.length > 0) {
      let labelEntry = this.labels[v];
      console.log('labelEntry::'+this.labelEntry);
      this._title = labelEntry?.length > 0 ? labelEntry : v;
    } else {
      this._title = v;
    }
  }

  @api
  titleFontFamily;
  @api
  titleFontColor;

  @api
  type;

  @api
  styleCss;

  @api
  legendPosition;
  @api
  legendFontFamily;
  @api
  legendFontColor;

  @api
  colorPalette = "default";

  _customColorPalette = [];
  @api
  get customColorPalette() {
    return this._customColorPalette;
  }
  set customColorPalette(v) {
    try {
      this._customColorPalette = Array.isArray(v) ? v : JSON.parse(v);
    } catch (e) {
      this._customColorPalette = [];
    }
  }

  @api
  fill = false;

  dimensionsLabels;
  _detailsLabels = [];
  @api
  get detailsLabels() {
    return this._detailsLabels;
  }
  set detailsLabels(v) {
    try {
      this._detailsLabels = Array.isArray(v) ? v : JSON.parse(v);
    } catch (e) {
      this._detailsLabels = [];
    }
  }

  // This is where the data are build and given to the chart.
  // It is set either directly via the app builder
  // or by the soql setter which call the imperative apex method
  // or by the handler setter which call the imperative apex method
  _throttlingDetails = false;
  _details = [];
  @api
  get details() {
    return this._details;
  }
  set details(v) {
    try {
      const data = v ? (Array.isArray(v) ? v : JSON.parse(v)) : null;
      if (!data || this._throttlingDetails) return;

      this._throttlingDetails = true;
      Promise.resolve()
        .then(() => {
          this._throttlingDetails = false;

          // Build the data structure to use to iterate
          // and create data component in the template
          this.allZero = data.filter((x) => !!x.detail)[0].allZero;
          const palette =
            this.colorPalette === "custom"
              ? this.customColorPalette
              : ChartBuilder.DEFAULT_PALETTE[this.colorPalette];
          this.dimensionsLabels = [
            ...new Set(data.map((x) => x.labels).flat())
          ];
          this._details = data
            .filter((x) => !!x.detail)
            .map((x, i) => ({
              detail: x.detail,
              labels: this._detailsLabels[i],
              uuid: x.uuid || nanoid(4),
              bgColor:
                x.bgColor || this.isDimensionable
                  ? x.detail.map((_, j) => palette[j % palette.length])
                  : palette[i % palette.length],
              fill: this.fill
            }));
          this.error = false;
        })
        .catch((error) => this.errorCallback(error));
        console.log('this._details'+JSON.stringify(this._details));
    } catch (error) {
      console.error(error);
      this.errorCallback(error);
    }
    this.isLoaded = true;
  }

  handleChange(event) {
    console.log('this.disableclassfInput::'+this.disableclassfInput + ' event.detail.fieldId::' + JSON.stringify(event.detail.fieldId));
    
    if (this.context[event.detail.fieldId] !== event.detail.value) {
      this.context[event.detail.fieldId] = event.detail.value;
      
      this.disableclassfInput = this.context.conformanceType == 'Inditex The List' ? false : true;
      
      console.log('event.detail.value::'+JSON.stringify(event.detail.value));
      if (this._handler) {
        console.log('this.context::'+JSON.stringify(this.context));
        // pass the custom handler to the getData service from the server
        this._getChartDataHandler(
          this._handler,
          this.handlerOptions && this.context
            ? JSON.stringify(this.context)
            : this.recordId
        );
      }
    }
  }

  connectedCallback() {
    this._getSupplierLocationsListhandler();
    this._getSupplierTypesListhandler();
    this._getInventoryTypesListhandler();
    this._getConformanceTypeListhandler();
    this._getClassificationListhandler();
    this._getIsSupplierUser();
    if (this._handler) {
      // pass the custom handler to the getData service from the server
      this._getChartDataHandler(
        this._handler,
        this.handlerOptions && this.context
          ? JSON.stringify(this.context)
          : this.recordId
      );
    }
  }
  
  context = {}; // options set fields in context;
  _throttlingOptions = false;
  @track _options = [];
  @api
  get options() {
    return this._options;
  }
  set options(v) {
    try {
      const data = v ? (isObject(v) ? v : JSON.parse(v)) : null;
      if (!data || this._throttlingOptions) return;

      this._throttlingOptions = true;
      Promise.resolve()
        .then(() => {
          this._throttlingOptions = false;
          this._options = data;
          // Store current selections in context for requesting data.
          if (this._options?.fieldId && this._options?.value) {
            this.context[this._options.fieldId] = this._options.value;
            let level2 = this._options.options?.find(
              (o) => o.value === this._options.value
            );
            if (level2 && level2.fieldId && level2.options) {
              this.context[level2.fieldId] = level2.value;
              let level3 = level2.options?.find(
                (o) => o.value === level2.value
              );
              if (level3 && level3.fieldId && level3.options) {
                this.context[level3.fieldId] = level3.value;
              }
            }
          }
          this.error = false;
        })
        .catch((error) => this.errorCallback(error));
    } catch (error) {
      console.error(error);
      this.errorCallback(error);
    }
    this.isOptionsLoaded = true;
  }
  @api
  get secondOptions() {
    return this._options?.value && this._options?.options
      ? this._options.options.find((o) => o.value === this._options.value)
          .selector
      : undefined;
  }

  @track _locations = [];
  @api
  get locations(){
    this._locations;
  }
  set locations(v){
    const data = v ? (isObject(v) ? v : JSON.parse(v)) : null;
      this._locations = data.locations;
      if (data.fieldId && data.value) {
        this.context[data.fieldId] = data.value;
      }
  }

  @track _suppTypes = [];
  @api
  get suppTypes(){
    this._suppTypes;
  }
  set suppTypes(v){
    const data = v ? (isObject(v) ? v : JSON.parse(v)) : null;
      this._suppTypes = data.supplierTypes;
      if (data.fieldId && data.value) {
        this.context[data.fieldId] = data.value;
      }
  }

  @track _invTypes = [];
  @api
  get invTypes(){
    this._invTypes;
  }
  set invTypes(v){
    const data = v ? (isObject(v) ? v : JSON.parse(v)) : null;
      this._invTypes = data.inventoryTypes;
      if (data.fieldId && data.value) {
        this.context[data.fieldId] = data.value;
      }
  }

  @track _confTypes = [];
  @api
  get confTypes(){
    this._confTypes;
  }
  set confTypes(v){
    const data = v ? (isObject(v) ? v : JSON.parse(v)) : null;
      this._confTypes = data.conformanceTypes;
      if (data.fieldId && data.value) {
        this.context[data.fieldId] = data.value;
      }
  }

  @track _classifications = [];
  @api
  get classifications(){
    this._classifications;
  }
  set classifications(v){
    const data = v ? (isObject(v) ? v : JSON.parse(v)) : null;
      this._classifications = data.classifications;
      if (data.fieldId && data.value) {
        this.context[data.fieldId] = data.value;
      }
  }

  _soql;
  @api
  get soql() {
    return this._soql;
  }
  set soql(v) {
    this._soql = v;
    if (this._soql) {
      // sanitize query
      // replace recordId with the sanitize recordId
      this._soql = this._soql.replace(
        /:recordId/g,
        `'${
          this.recordId
            ? this.recordId.replace("'", "\\'")
            : ChartBuilder.FAKE_ID
        }'`
      );
      // pass the SOQL to the getData service from the server
      this._getChartDataHandler(
        ChartBuilder.SOQL_DATA_PROVIDER_APEX_TYPE,
        this._soql
      );
    }
  }

  _handler;
  @api
  get handler() {
    return this._handler;
  }
  set handler(v) {
    this._handler = v;
    if (this._handler) {
      // pass the custom handler to the getData service from the server
      this._getChartDataHandler(
        this._handler,
        this.handlerOptions && this.context
          ? JSON.stringify(this.context)
          : this.recordId
      );
    }
  }

  _handlerOptions;
  @api
  get handlerOptions() {
    return this._handlerOptions;
  }
  set handlerOptions(v) {
    this._handlerOptions = v;
    if (this._handler && this._handlerOptions) {
      // pass the custom handler to the getOptions service from the server
      this._getChartOptionsHandler(this._handler, this.recordId);
    }
  }

  get isCircular() {
    return CIRCULAR_TYPE.includes(this.type);
  }

  get isRadial() {
    return RADIAL_TYPE.includes(this.type);
  }

  get isDimensionable() {
    return DIMENSIONABLE_TYPES.includes(this.type);
  }

  isLoaded = false;
  allZero = true;
  error = false;
  stack;

  errorCallback(error, stack) {
    console.error(JSON.stringify({ error, stack }));
    this.error = error;
    this.stack = stack;
    this._details = null;
    this._detailsLabels = null;
    this.dimensionsLabels = null;
  }

  handleError(evt) {
    this.errorCallback(evt.detail.error, evt.detail.stack);
  }

  // call the apex method to get locations from the server
  _getSupplierLocationsListhandler() {
    getSupplierLocationsList()
      .then((result) => {
        // eslint-disable-next-line @lwc/lwc/no-api-reassignments
        if(result == 'Data Not Available'){
          this.showLocationDiv = false;
        }
        else if(result !== 'Data Not Available'){
          this.locations = result;
          this.showLocationDiv = true;
        }
      })
      .catch((error) => {
        this.errorCallback(error.body.message);
      });
  }

  // call the apex method to get supplier type from the server
  _getSupplierTypesListhandler() {
    getSupplierTypeList()
      .then((result) => {
        // eslint-disable-next-line @lwc/lwc/no-api-reassignments
        if(result == 'Data Not Available'){
          this.showSuppTypeDiv = false;
        }
        else if(result !== 'Data Not Available'){
          this.suppTypes = result;
          this.showSuppTypeDiv = true;
        }
      })
      .catch((error) => {
        this.errorCallback(error.body.message);
      });
  }

  // call the apex method to get inventory type from the server
  _getInventoryTypesListhandler() {
    getInventoryTypeList()
      .then((result) => {
        // eslint-disable-next-line @lwc/lwc/no-api-reassignments
        if(result == 'Data Not Available'){
          this.showInvTypeDiv = false;
        }
        else if(result !== 'Data Not Available'){
          this.invTypes = result;
          this.showInvTypeDiv = true;
        }
      })
      .catch((error) => {
        this.errorCallback(error.body.message);
      });
  }

  // call the apex method to get conformance type from the server
  _getConformanceTypeListhandler() {
    getConformanceTypeList()
      .then((result) => {
          this.confTypes = result;
      })
      .catch((error) => {
        this.errorCallback(error.body.message);
      });
  }

  // call the apex method to get classification type from the server
  _getClassificationListhandler() {
    getClassificationList()
      .then((result) => {
          this.classifications = result;
      })
      .catch((error) => {
        this.errorCallback(error.body.message);
      });
  }

   // call the apex method to know the loggedin user from the server
   _getIsSupplierUser() {
    isSupplierUser()
      .then((result) => {
        console.log('isSupplier::'+JSON.stringify(result))
          this.isSupplierUser = result;
      })
      .catch((error) => {
        this.errorCallback(error.body.message);
      });
  }

  // call the apex method to get options from the server
  _getChartOptionsHandler(handlerName, input) {
    this.isOptionsLoaded = false;
    getChartOptions({ chartDataProviderType: handlerName, ctx: input })
      .then((result) => {
        // eslint-disable-next-line @lwc/lwc/no-api-reassignments
        this.options = result;
      })
      .catch((error) => {
        this.errorCallback(error.body.message);
      });
  }

  // call the apex method to get data from the server
  _getChartDataHandler(handlerName, input) {
    console.log('Inside this::' + JSON.stringify(handlerName) + '::::::' +JSON.stringify(input) );
    this.isLoaded = false;
    getChartData({ chartDataProviderType: handlerName, ctx: input })
      .then((result) => {
        // eslint-disable-next-line @lwc/lwc/no-api-reassignments
        this.details = result;
        console.log('result is::' + JSON.stringify(this.details));
      })
      .catch((error) => {
        this.errorCallback(error.body.message);
      });
  }

  // https://www.lightningdesignsystem.com/guidelines/charts/#Chart-Color
  /*
  iterate over data and map a palette color modulo DEFAULT_PALETTE size with opacity and then decrement opacity
  */
  static DEFAULT_PALETTE = {
    //Default Palette: #52B7D8, #E16032, #FFB03B, #54A77B, #4FD2D2, #E287B2
    default: [
      "rgba(82,183,216,1)",
      "rgba(225,96,50,1)",
      "rgba(255,176,59,1)",
      "rgba(84,167,123,1)",
      "rgba(79,210,210,1)",
      "rgba(226,135,178,1)"
    ],
    //Color Safe: #529EE0, #D9A6C2, #08916D, #F59B00, #006699, #F0E442
    colorsafe: [
      "rgba(82,158,224,1)",
      "rgba(217,166,194,1)",
      "rgba(8,145,109,1)",
      "rgba(245,155,0,1)",
      "rgba(0,102,153,1)",
      "rgba(240,228,66,1)"
    ],
    //Light: #3296ED, #77B9F2, #9D53F2, #C398F5, #26ABA4, #4ED4CD
    light: [
      "rgba(50,150,237,1)",
      "rgba(119,185,242,1)",
      "rgba(157,83,242,1)",
      "rgba(195,152,245,1)",
      "rgba(38,171,164,1)",
      "rgba(78,212,205,1)"
    ],
    //Bluegrass: #C7F296, #94E7A8, #51D2BB, #27AAB0, #116985, #053661
    bluegrass: [
      "rgba(199,242,150,1)",
      "rgba(148,231,168,1)",
      "rgba(81,210,187,1)",
      "rgba(39,170,176,1)",
      "rgba(17,105,133,1)",
      "rgba(5,54,97,1)"
    ],
    //Sunrise: #F5DE98, #F5C062, #F59623, #CE6716, #762F3D, #300561
    sunrise: [
      "rgba(245,222,152,1)",
      "rgba(245,192,98,1)",
      "rgba(245,150,35,1)",
      "rgba(206,103,22,1)",
      "rgba(118,47,61,1",
      "rgba(48,5,97,1)"
    ],
    //Water: #96F2EE, #68CEEE, #2D9CED, #0E6ECE, #073E92, #051C61
    water: [
      "rgba(150,242,238,1)",
      "rgba(104,206,238,1)",
      "rgba(45,156,237,1)",
      "rgba(14,110,206,1)",
      "rgba(7,62,146,1)",
      "rgba(5,28,97,1)"
    ],
    //Watermelon: #F598A7, #F56580, #F4284E, #C11C2F, #5C3F22, #0A611B
    watermelon: [
      "rgba(245,152,167,1)",
      "rgba(245,101,128,1)",
      "rgba(244,40,78,1)",
      "rgba(193,28,47,1)",
      "rgba(92,63,34,1)",
      "rgba(10,97,27,1)"
    ]
  };

  static FAKE_ID = "xxxxxxxxxxxxxxx";
  static SOQL_DATA_PROVIDER_APEX_TYPE = "SOQLDataProvider";
}