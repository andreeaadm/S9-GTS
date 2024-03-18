import { LightningElement } from 'lwc';

import header from '@salesforce/label/c.GTS_Analytics_Header';
import helpTextParagraph from '@salesforce/label/c.GTS_Analytics_Help_Text_Paragraph';
import jobReportDashboard from '@salesforce/label/c.GTS_Analytics_Job_Report_Dashboard';
import licenseRegistrationDashboard from '@salesforce/label/c.GTS_Analytics_License_Registration_Dashboard';

export default class GtsAnalyticsExpCloudFooter extends LightningElement {
    labels = {
        header,
        helpTextParagraph,
        jobReportDashboard,
        licenseRegistrationDashboard
    }
}