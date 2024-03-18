import { LightningElement , api } from 'lwc';
import basePath from '@salesforce/community/basePath';
import IntertekRoundel from '@salesforce/resourceUrl/iconsiCare'
import Linkedin from '@salesforce/resourceUrl/iconsiCare';
import PRIVACY_POLICY from '@salesforce/label/c.iCare_Privacy_Policy';
import COOKIE_POLICY from '@salesforce/label/c.iCare_Cookie_Policy';
import TERMS_AND_CONDITIONS from '@salesforce/label/c.iCare_Term_and_Conditions';
import CONTACT_US from '@salesforce/label/c.iCare_Footer_Contact';

export default class ICarePublicPortalFooter extends LightningElement {
    IntertekRoundel = IntertekRoundel + '/IntertekRoundel.svg';
    Linkedin = Linkedin  + '/linkedin.svg';

    customLabel = {
        PRIVACY_POLICY,
        COOKIE_POLICY,
        TERMS_AND_CONDITIONS,
        CONTACT_US
    }
}