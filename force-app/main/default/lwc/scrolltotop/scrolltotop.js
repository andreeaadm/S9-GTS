import {LightningElement, track} from 'lwc';
import FONTAWESOME from '@salesforce/resourceUrl/FontAwesome5';
import {loadStyle} from 'lightning/platformResourceLoader';

export default class Scrolltotop extends LightningElement {

    @track
    displayBtn = false;

	renderedCallback() {
		loadStyle(this, FONTAWESOME + '/css/fontawesome.min.css');
	}

    connectedCallback() {
        window.addEventListener("scroll", function (evt) {
            // Debouncing this function: do not update the reactive property as
            // long as this function is being called within a delay of 300 ms.
            // This is to avoid a very large number of Apex method calls.
            window.clearTimeout(this.delayTimeout);
            this.delayTimeout = setTimeout(() => {
                this.checkScroll();
            },20);
        }.bind(this));
    }

    checkScroll() {
        if (window.scrollY > 20) {
            this.displayBtn = true;
        } else {
            this.displayBtn = false;
        }
    }

    // When the user clicks on the button, scroll to the top of the document
    scrollToTop() {
        var scrollOptions = {
            left: 0,
            top: 0,
            behavior: 'smooth'
        }
        window.scrollTo(scrollOptions);
    }
}