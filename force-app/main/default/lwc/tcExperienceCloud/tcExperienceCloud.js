import { api } from "lwc";
import getUserType from "@salesforce/apex/TC_ExperienceCloud.getUserType";

const USERTYPE_ADMIN = 1;
const USERTYPE_STANDARD = 2;
const USERTYPE_SUPPLIER = 4;
const USERTYPE_BRAND = 8;

export default class TcExperienceCloud {
  type;
  error;
  constructor() {
    getUserType()
      .then((result) => {
        this.type = result;
        this.error = undefined;
      })
      .catch((error) => {
        console.error(error);
        this.error = error;
      });
  }
  get isToxClearUser() {
    return (
      (this.type & (USERTYPE_SUPPLIER | USERTYPE_BRAND)) !== 0 &&
      (this.type & (USERTYPE_ADMIN | USERTYPE_STANDARD)) !== 0
    );
  }
  get isNotToxClearUser() {
    return !this.isToxClearUser;
  }
  get isAdminUser() {
    return (this.type & USERTYPE_ADMIN) !== 0;
  }
  get isStandardUser() {
    return (this.type & USERTYPE_STANDARD) !== 0;
  }
  get isSupplierUser() {
    return (this.type & USERTYPE_SUPPLIER) !== 0;
  }
  get isBrandUser() {
    return (this.type & USERTYPE_BRAND) !== 0;
  }
  get isSupplierAdminUser() {
    return (
      (this.type & (USERTYPE_SUPPLIER | USERTYPE_ADMIN)) ===
      (USERTYPE_SUPPLIER | USERTYPE_ADMIN)
    );
  }
  get isSupplierStandardUser() {
    return (
      (this.type & (USERTYPE_SUPPLIER | USERTYPE_STANDARD)) ===
      (USERTYPE_SUPPLIER | USERTYPE_STANDARD)
    );
  }
  get isBrandAdminUser() {
    return (
      (this.type & (USERTYPE_BRAND | USERTYPE_ADMIN)) ===
      (USERTYPE_BRAND | USERTYPE_ADMIN)
    );
  }
  get isBrandStandardUser() {
    return (
      (this.type & (USERTYPE_BRAND | USERTYPE_STANDARD)) ===
      (USERTYPE_BRAND | USERTYPE_STANDARD)
    );
  }
}