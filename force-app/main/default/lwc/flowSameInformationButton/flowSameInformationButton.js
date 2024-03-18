import { LightningElement, api } from "lwc";
import {
  FlowAttributeChangeEvent,
  FlowNavigationNextEvent,
  FlowNavigationBackEvent,
  FlowNavigationFinishEvent
} from "lightning/flowSupport";

const alignments = [
  { input: "left", value: "slds-float_left" },
  { input: "center", value: "slds-align_absolute-center", default: true },
  { input: "right", value: "slds-float_right" }
];

const valuesToDisable = ["Submit Form", "Submit Favourite"];

export default class FlowButton extends LightningElement {
  //Input only
  @api buttonLabel;
  @api buttonValue;
  @api buttonDescriptionText;
  @api isDisabled;

  //Output only
  @api selectedValue;

  // Public variable floatLeft that controls the float direction of the buttons. It's boolean, with false meaning left and true meaning right
  @api alignment;
  // Evaluates the proper class for button alignment based on the user's input
  get floatClass() {
    return this.getValueFromInput(alignments, this.alignment);
  }

  handleClick(event) {
    // Get the value from the clicked button
    const clickedButtonValue = event.target.value;

    // Dispatch a FlowAttributeChangeEvent to update the selectedValue attribute
    this.dispatchEvent(
      new FlowAttributeChangeEvent("selectedValue", clickedButtonValue)
    );

    // Copy information to the next fields based on your flow's logic
    this.copyInformationToNextFields(clickedButtonValue);

    // Continue to the next screen in the flow
    this.dispatchEvent(new FlowNavigationNextEvent());
  }

  copyInformationToNextFields(clickedButtonValue) {
    // Add your logic here to determine what information to copy to the next fields
    // You can use FlowAttributeChangeEvent to update flow variables for the next fields
    // For example:
    this.dispatchEvent(
      new FlowAttributeChangeEvent("nextFieldVariable", clickedButtonValue)
    );
  }

  getValueFromInput(
    valueMap,
    input,
    inputParam = "input",
    valueParam = "value",
    defaultParam = "default"
  ) {
    if (!valueMap) return null;

    let returnValue;
    if (input) {
      returnValue = valueMap.find((el) => {
        return el[inputParam].toLowerCase() === input.toLowerCase();
      });
    }
    if (!returnValue) {
      returnValue = valueMap.find((el) => {
        return el[defaultParam];
      });
    }
    if (!returnValue) return null;
    return returnValue[valueParam];
  }

  /*Sets the button attribute to disabled if the attribute is not defined based on its value - this allows reactive components that 
      have not had their values set to be used to set the disabled attribute (e.g confirm terms and conditions flow checkbox element)
    */
}