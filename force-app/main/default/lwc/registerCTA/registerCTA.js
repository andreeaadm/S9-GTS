import { LightningElement, track } from "lwc";
import REGISTER_URL from "@salesforce/label/c.MTC_System_Register_URL";

export default class RegisterCTA extends LightningElement {
  @track registerURL = REGISTER_URL;
}