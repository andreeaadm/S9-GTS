/**
 * Refer to noUiSlider documentation for examples of sliderConfigs you can pass into slider via c-input
 * https://refreshless.com/nouislider/examples/
 */
import { LightningElement, api, track } from 'lwc';
import { loadStyle, loadScript } from "lightning/platformResourceLoader";
import nouislider from "@salesforce/resourceUrl/nouislider";

export default class Slider extends LightningElement {
    @api get step() {
        return parseFloat(this._step); // temporary - would break decimal steps like 0.1
    }
    set step(value) {
        this._step = value;
    }
    @api get minRange() {
        return parseFloat(this._minRange);
    }
    set minRange(value) {
        this._minRange = value;
        this.updateRange(this.minRange, this.maxRange);
    }
    @api get maxRange() {
        return parseFloat(this._maxRange);
    }
    set maxRange(value) {
        this._maxRange = value;
        this.updateRange(this.minRange, this.maxRange);
    }
    @api get values() {
        return this._values;
    }
    set values(value) {
        if(value) {
            value = Array.isArray(value) ? value : value.split(',');
            this._values = value;
            this.updateValues(value);
        }
    }
    /* TODO: fix disabled. Doesn't seem to be respected by noUiSlider.
    @api get disabled() {
        return this._disabled;
    }
    set disabled(value) {
        this._disabled = value;
        if(this.slider) {
            if(value) {
                this.slider.noUiSlider.setAttribute('disabled', value);
            } else {
                this.slider.noUiSlider.removeAttribute('disabled');
            }
        }
    }
    */
    /* NOTE: slider doesn't currently support vertical orientation due to needing a height to be set */
    @api get sliderConfig() {
        return this._sliderConfig;
    }
    set sliderConfig(value) {
        this._sliderConfig = value;
        if(this.slider) {
            this.slider.noUiSlider.updateOptions(value);
        }
    }
    
    @track _minRange = 200000;
    @track _maxRange = 1200000;
    @track _values = [200000, 1200000];
    @track _step = 50000;
    @track _disabled = false;
    @track _sliderConfig;

    slider;

    connectedCallback() {
        this.initSliderCallback = this.initSlider.bind(this);
        this.onSliderValuesChangeCallback = this.onSliderValuesChange.bind(this);
    }

    renderedCallback() {
        Promise.all([
            loadStyle(this, nouislider + "/nouislider.min.css"),
            loadScript(this, nouislider + "/nouislider.min.js")
        ]).then(this.initSliderCallback);
    }

    /**
     * Sets the slider to the specified values
     * @param {*} values array of values
     */
    updateValues(values) {
        if (this.slider) {
            this.slider.noUiSlider.set(values);
        }
    }

    /**
     * Updates the slider range to the specified values
     * @param {*} min minimum range
     * @param {*} max maximum range
     */
    updateRange(min, max) {
        if(this.slider) {
            this.slider.noUiSlider.updateOptions({
                range: {
                    'min': min,
                    'max': max
                }
            });
        }
    }

    /**
     * init Slider with default values
     */
    initSlider() {
        // Get HTML element which will be replaced with the slider
        this.slider = this.template.querySelector(".slider");

        // Create slider
        window.noUiSlider.create(this.slider,
            this.sliderConfig ? this.sliderConfig : {
                start: this.values,
                connect: true,
                tooltips: true,
                format: {
                    to: function ( value ) {
                        if (value >= 1000000) {
                            return (Math.round(value / 10000) / 100) + "M";
                        } else if (value > 100000) {
                            return Math.round(value / 1000) + "K";
                        } else {
                            return Math.round(value);
                        }
                    },
                    from: function ( value ) {
                        return value;
                    }
                },
                step: this.step,
                range: {
                    "min": this.minRange,
                    "max": this.maxRange
                }
                /* TODO: fix disabled. Doesn't seem to be respected by noUiSlider.
                disabled: this.disabled
                */
            }
        );

        // Add handler to when the values change
        this.slider.noUiSlider.on("change", this.onSliderValuesChangeCallback);
    }

    /**
     * Handler for the change in slider values
     * @param {array} range Current slider values
     * @param {number} handle Handle that caused the event
     * @param {array} unencoded New slider values without formatting
     * @param {boolean} tap Event was caused by the user tapping the slider
     * @param {array} positions Left offset of the handles
     */
    onSliderValuesChange(range, handle, unencoded, tap, positions) {
        this.dispatchEvent(new CustomEvent("change", {
            cancelable: true,
            composed: true,
            bubbles: true,
            detail: {
                values: unencoded
            }
        }));
    }
}