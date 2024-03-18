import { LightningElement, api, track } from 'lwc';

import DOWNLOAD from '@salesforce/label/c.GMA_Download';
import LINK from '@salesforce/label/c.GTS_Link';
import NAME from '@salesforce/label/c.iCare_Portal_Name';
import UPLOADED_DATE from '@salesforce/label/c.GTS_Uploaded_Date';

const PAGE_SIZE_OPTIONS = [25, 50, 100];

export default class GtsDocumentsTable extends LightningElement {
    @api records;
    @api keyValue;
    @track documents;

    sfdcBaseURL;

    columns = [
        { label: NAME, fieldName: 'name', type: 'text', hideDefaultActions: "false" },
        { label: UPLOADED_DATE, fieldName: 'uploadedDate', type: 'text', hideDefaultActions: "false" },
        { label: LINK, fieldName: 'downloadURL', type: 'url', typeAttributes: { label: DOWNLOAD}, cellAttributes: { iconName: 'utility:download', iconPosition: 'left' },  hideDefaultActions: "false" },

    ];

    pageSizeOptions = PAGE_SIZE_OPTIONS;
    @track pageSize = PAGE_SIZE_OPTIONS[0];
    @track currentPage = 1;

    get totalPages() {
      return Math.ceil(this.documents.length / this.pageSize);
    }
    get isFirstPage() {
      return (this.currentPage === 1);
    }
    get isLastPage() {
      return (this.currentPage === this.totalPages);
    }

    get currentPageRecords() {
      const startIndex = (this.currentPage - 1) * this.pageSize;
      const endIndex = startIndex + this.pageSize;
      return this.documents.slice(startIndex, endIndex);
    }

    connectedCallback() {
      this.sfdcBaseURL = window.location.origin;
      this.documents = this.records[this.keyValue].map(obj => ({ ...obj, downloadURL: this.sfdcBaseURL + obj.link }));

    }

    handlePageSizeChange(event) {
        this.pageSize = parseInt(event.target.value, 10);
        this.currentPage = 1;
    }

    handleFirstPage() {
        this.currentPage = 1;
    }

    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
        }
    }

    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
        }
    }

    handleLastPage() {
        this.currentPage = this.totalPages;
    }
}