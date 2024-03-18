import { LightningElement, api, track } from 'lwc';
import { mapUtility, setMapData } from './mapUtility';
import { utilFunctions } from "c/gmaelAccessPassportUtils";
const WAIT_TIME = 1000;
export default class GmaelAPDynamicMap extends LightningElement {

    @api reportData;
    jVectorMapPng = mapUtility.GMAEL_JVECTOR_MAP_PNG;
    labels = utilFunctions.labels;    
    listOfRegionCountries = [];
    isMapLoaded = false;
    showLoader = true;

    renderedCallback() {    
        
        try {

            localStorage.removeItem('selectedCountries');
            localStorage.removeItem('selected-regions');
            if (this.isMapLoaded) {
            
                //this.showLoader = false;
                return;
            }
            
            this.showLoader = true;
            this.isMapLoaded = true;
            this.handelLoadJVectorAssets(this);
        } catch (error) {

            console.log('Error:', error);
            this.showLoader = false;
        }
    }

    handelLoadJVectorAssets(_this) {

        mapUtility.loadJVectorAssets(_this, undefined).then(() => { 

            setTimeout(() => {
                
                if (jvm) {
                    
                    mapUtility.initializeJVectorMap(_this, _this.initializeMapData);
                    _this.isMapLoaded = true;
                    //_this.showLoader = false; 
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
        _this.showLoader = false; 
        _this.template.querySelector('.map-container').removeAttribute('style');
    }

    handelRetrieveRegionsByCountries() {

        this.listOfRegionCountries = [];
        let selectedCountries = mapUtility.retrieveSelectedRegions();        

        utilFunctions.fireCustomEvent(this, 'countryselect', JSON.parse(selectedCountries));

        if (selectedCountries.length < 3) {
            
            return;
        }

        utilFunctions.retrieveRegionsByCountries({countryIds: selectedCountries}).then(result =>{

            this.listOfRegionCountries = [];

            result.forEach(region => {
                
                region.GMAEL_Countries__r.forEach(country => {
                    
                    this.listOfRegionCountries.push(country.Name);
                });
            });

        }).catch(error =>{

            utilFunctions.toast(this, 'Error', error.body.message || error.message, 'error');
        })
    }

    @api 
    resetCountriesOnMap(){

        mapUtility.resetJVectorMap();
    }

    @api
    getSelectedCountries() {

        return mapUtility.retrieveSelectedRegions();    
    }
}