import { LightningElement, api, wire, track } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import ChartJSLib from "@salesforce/resourceUrl/chartjs_v280";

const DOUGHNUT_CHART = 'doughnut';
const POSITION_RIGHT = 'right';

export default class ChartJS extends LightningElement {

    @api chartData;
    @api dimensionsLabels;

    chartInitialized = false;
    chartConfig;
    
    connectedCallback() {

        if (!this.chartData && !this.dimensionsLabels) {
            return;
        }

        let chartDataSet = JSON.parse(JSON.stringify(this.chartData[0]));
        this.chartConfig = {
            type: DOUGHNUT_CHART,
            data: {
                labels: this.dimensionsLabels || [],
                datasets: [{
                    backgroundColor: chartDataSet.bgColor || [],
                    data: chartDataSet.detail || []
                }]
            },
            options: {
                legend: {
                    position: POSITION_RIGHT,
                }
            }
        };
    }

    renderedCallback() {
        
        if (this.chartInitialized) {
            return;
        }

        this.chartInitialized = true;

        loadScript(this, ChartJSLib)
        .then(() => {
            const canvas = this.template.querySelector('canvas');
            const ctx = canvas.getContext('2d');
            new window.Chart(ctx, this.chartConfig);
        })
        .catch(error => {
            console.error('Error loading chart:', error);
        });
    }
}