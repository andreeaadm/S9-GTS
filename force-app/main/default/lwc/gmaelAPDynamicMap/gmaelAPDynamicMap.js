import { LightningElement, api, track } from 'lwc';
import { mapUtility, setMapData } from './mapUtility';
import { utilFunctions } from "c/gmaelAccessPassportUtils";
const WAIT_TIME = 1000;
export default class GmaelAPDynamicMap extends LightningElement {

    @api reportData;
    @track showRegionSection = false;
    labels = utilFunctions.labels;    
    showCountriesOfTheRegion = false;
    listOfRegionCountries = [];
    isMapLoaded = false;
    showLoader = false;

    renderedCallback() {    
        
        if (this.isMapLoaded) {
            
            return;
        }
        
        this.showLoader = true;
        this.isMapLoaded = true;
        this.handelLoadJVectorAssets(this);
    }

    handelLoadJVectorAssets(_this) {

        mapUtility.loadJVectorAssets(_this, undefined).then(() => { 

            setTimeout(() => {
                
                if (jvm) {
                    
                    mapUtility.initializeJVectorMap(_this, _this.initializeMapData);
                    _this.isMapLoaded = true;
                    _this.showLoader = false; 
                } else {
                    
                    _this.isMapLoaded = false;
                }
            }, WAIT_TIME);
        }).catch((error) => {
    
            console.log('jVectorMap Error:', error.message);
            _this.isMapLoaded = false;
        });
    }

    initializeMapData(_this, mapInstance) {
        
        mapUtility.data = _this.reportData?.countriesIso2;

        setMapData(_this.reportData?.approvedCountries, _this.reportData?.countriesIso2);
        mapUtility.refreshMap(mapInstance, _this.reportData?.countriesIso2);

        if (_this.reportData?.isReportObject && _this.reportData?.reportId) {
            
            mapUtility.setDefaultCountries(
                mapInstance, 
                _this.reportData?.countriesToBePrePopup
            );
        }
    }

    handelRetrieveRegionsByCountries() {

        this.listOfRegionCountries = [];
        let selectedCountries = mapUtility.retrieveSelectedRegions();        

        utilFunctions.fireCustomEvent(this, 'countryselect', JSON.parse(selectedCountries));

        if (selectedCountries.length < 3) {
            
            this.showRegionSection = false;
            return;
        }

        utilFunctions.retrieveRegionsByCountries({countryIds: selectedCountries}).then(result =>{

            this.listOfRegionCountries = [];

            result.forEach(region => {
                
                region.GMAEL_Countries__r.forEach(country => {
                    
                    this.listOfRegionCountries.push(country.Name);
                });
            });

            if (this.listOfRegionCountries.length > 0) {

                this.showRegionSection = true;
            } else {
                
                this.showRegionSection = false;
            }
        }).catch(error =>{

            utilFunctions.toast(this, 'Error', error.body.message || error.message, 'error');
        })
    }

    @api 
    resetCountriesOnMap(){

        mapUtility.resetJVectorMap();
        this.showRegionSection = false;
    }

    openModal() {     
        
        this.showCountriesOfTheRegion = true;      
    }

    closeModal() {

        this.showCountriesOfTheRegion = false;
    }
}