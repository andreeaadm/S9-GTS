import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import J_VECTOR_MAP from '@salesforce/resourceUrl/jquery_jvectormap_2_0_5';
import GMAEL_JVECTOR_MAP_PNG from '@salesforce/resourceUrl/gmael_jvectormap_png';
let jVectorMap = null;

let data = [];
let countriesData = [];

export function setMapData(rawData, parsedData) {

    countriesData = JSON.parse(JSON.stringify(rawData));
    data = JSON.parse(JSON.stringify(parsedData));
};

export function getData() {
    return data;
}

const loadJVectorAssets = async function (_this, promises) {

    var cacheBuster = ''; //`?v=${Date.now()}`;
    let jVectorMapPromises = [
        loadStyle(_this, J_VECTOR_MAP + "/lib_new/jquery-jvectormap-2.0.5.css" + cacheBuster),
        loadScript(_this, J_VECTOR_MAP + "/lib/jquery-1.8.2.min.js" + cacheBuster),
        loadScript(_this, J_VECTOR_MAP + "/lib_new/jquery-jvectormap-2.0.5.min.js" + cacheBuster),
        loadScript(_this, J_VECTOR_MAP + "/lib/jquery-jvectormap-world-mill-en.js" + cacheBuster)
    ];

    return await Promise.allSettled((promises ? promises : jVectorMapPromises));
}

let initializeJVectorMap = function (_this, callback) {

    try {        
        
        if (!jvm && !jvm?.Map) {

            _this.isMapLoaded = false;
            return;
        }

        mapUtility.jVectorMap = new jvm.Map({

            container: jQuery(_this.template.querySelector('.map-inner-container')),
            map: 'world_mill_en',
            panOnDrag: true,
            backgroundColor: '#fff',
            zoomOnScroll: false,
            regionsSelectable: true,
            markersSelectable: true,
            markers: _this?.reportData?.smallCountries,
            markerStyle: {
                initial: {
                    fill: '#21B6D7',
                    stroke: '#fff',
                    "fill-opacity": 1,
                    "stroke-width": 1,
                    "stroke-opacity": 1,
                    r: 6
                },
                hover: {
                    fill: '#FFC700',
                    "fill-opacity": 1,
                    stroke: '#FFC700',
                    "stroke-width": 1,
                    cursor: 'pointer'
                },
                selected: {
                    fill: '#FFC700'
                },
                selectedHover: {
                    "fill-opacity": 0.8,
                }
            },
            focusOn: {

                x: 0.5,
                y: 0.5,
                scale: 1,
                animate: true
            },
            series: {

                regions: [{

                    scale: ['#21B6D7'],
                    normalizeFunction: 'polynomial',
                    values: mapUtility.data
                }]
            },
            regionStyle: {

                initial: {

                    fill: '#06213D',
                    "fill-opacity": 1,
                    stroke: 'none',
                    "stroke-width": 0,
                    "stroke-opacity": 1
                },
                selected: {

                    fill: '#FFC700'
                },
                hover: {

                    fill: '#FFC700'
                }
            },
            onRegionTipShow: function (e, el, code) {

                let data = getData();

                if (data[code] === 1) {

                    el.html(el.html());
                } else {

                    e.preventDefault();
                }
            },
            onRegionOver: function (e, code) {
                
                let data = getData();

                if (data[code] === 1) {

                    console.log(code);
                } else {

                    e.preventDefault();
                    return;
                }
            },
            onRegionClick: function (e, code) {

                let data = getData();               

                if (data[code] !== 1) {

                    e.preventDefault();
                    return;
                }
            },
            onRegionSelected: function (e, code) {

                let data = getData();

                if (data[code] !== 1) {

                    e.preventDefault();
                    return;
                }

                let regions = mapUtility.retrieveMatchJSONobjectsByListOfAttributes(mapUtility?.jVectorMap?.getSelectedRegions(), countriesData);
                let markers = mapUtility.retrieveMatchJSONobjectsByListOfAttributes(mapUtility?.jVectorMap?.getSelectedMarkers(), countriesData)
                
                let contactRegionAndMarkers = regions.concat(markers);

                if (window.localStorage) {

                    window.localStorage.setItem(
                        'selected-regions',
                        JSON.stringify(contactRegionAndMarkers)
                    );
                }

                try {
                    
                    _this.handelRetrieveRegionsByCountries();
                } catch (error) {
                    
                    console.log('onRegionSelected-error: ', error);
                }                
            },
            onMarkerSelected: function(e, code){
            
                let data = getData();

                if (data[code] !== 1) {

                    e.preventDefault();
                    return;
                }

                let regions = mapUtility.retrieveMatchJSONobjectsByListOfAttributes(mapUtility?.jVectorMap?.getSelectedRegions(), countriesData);
                let markers = mapUtility.retrieveMatchJSONobjectsByListOfAttributes(mapUtility?.jVectorMap?.getSelectedMarkers(), countriesData)
                
                let contactRegionAndMarkers = regions.concat(markers);
                
                if (window.localStorage) {
                    window.localStorage.setItem(
                        'selected-regions',
                        JSON.stringify(contactRegionAndMarkers)
                    );
                }

                try {
                    
                    _this.handelRetrieveRegionsByCountries();
                } catch (error) {
                    
                    console.log('onRegionSelected-error: ', error);
                }
            }
        });
        
        console.log('jVector Map Loaded - transaction Ended');
        callback(_this , mapUtility.jVectorMap);
        
    } catch (error) {
        
        console.log('mapUtility: ', error.message);
        setTimeout(() => {
            
            _this.isMapLoaded = false;
        }, _this.WAIT_TIME);
    }
}

let loadJVectorMap = function (_this, callback) {

    mapUtility.loadJVectorAssets().then(() => {

        console.log('jVector Lib Loading 01...');
    }).catch((error) => {

        console.log('jVectorMap Error:', error.message);
    }).finally(() => {

        setTimeout(() => {
            mapUtility.initializeJVectorMap(_this, callback);
        }, 2000);
    });
}

let retrieveSelectedRegions = function () {

    return window.localStorage.getItem('selected-regions');
}

let resetJVectorMap = function () {

    mapUtility?.jVectorMap?.clearSelectedRegions();
    mapUtility?.jVectorMap?.clearSelectedMarkers();
}

let refreshMap = function (mapInstance, data) {

    mapUtility.data = data;
    let map = mapInstance;
    map?.series?.regions[0]?.clear();
    map?.series?.regions[0]?.setValues(data);
}

let setDefaultCountries = function (mapInstance, data) {

    mapInstance?.setSelectedRegions(data.regions);
    mapInstance?.setSelectedMarkers(data.markers);
}

let parseDataToMapDataStructure = function (countries) {

    var processedData = {};

    for (var country in countries) {

        if (countries.hasOwnProperty(country)) {
            country = countries[country];

            // Store the modified value in the processed data object
            processedData[country.GMAEL_ISO_Code__c] = country;
        }
    }
    
    return processedData;
}

function processRegionValues(data) {
    var processedData = {};

    for (var regionCode in data) {

        if (data.hasOwnProperty(regionCode)) {

            // Store the modified value in the processed data object
            processedData[regionCode] = 1;
        }
    }

    return processedData;
}

const retrieveMatchJSONobjectsByListOfAttributes = function (stringArr, jsonArr) {
    // Create an empty array to store the matched results
    var matchedResults = [];

    // Loop through each JSON object in the array
    for (var i = 0; i < jsonArr.length; i++) {
        var jsonObj = jsonArr[i];

        // Check if the "GMAEL_ISO_Code__c" key exists in the current JSON object
        if (jsonObj.hasOwnProperty("GMAEL_ISO_Code__c")) {
            var value = jsonObj["GMAEL_ISO_Code__c"];

            // Loop through each string in the array
            for (var j = 0; j < stringArr.length; j++) {
                var searchString = stringArr[j];

                // Check if the current string matches the value of "GMAEL_ISO_Code__c"
                if (searchString === value) {
                    // Add the matched JSON object to the results array
                    matchedResults.push(jsonObj.Id);
                    break; // Exit the inner loop since we found a match
                }
            }
        }
    }

    return matchedResults;
}

const mapUtility = {

    refreshMap,
    data,
    jVectorMap,
    loadJVectorAssets,
    initializeJVectorMap,
    loadJVectorMap,
    resetJVectorMap,
    parseDataToMapDataStructure,
    processRegionValues,
    retrieveMatchJSONobjectsByListOfAttributes,
    retrieveSelectedRegions,
    setDefaultCountries,
    GMAEL_JVECTOR_MAP_PNG
}

export {

    mapUtility
}