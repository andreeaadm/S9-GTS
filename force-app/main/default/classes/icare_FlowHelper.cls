public with sharing class icare_FlowHelper {
  @InvocableMethod(
    label='Convert Multi-Picklist value to HTML'
    description='This takes an input of a multi-picklist and returns a String of HTML with break tags'
  )
  public static List<String> ConvertMultiPicklistHTML(
    List<String> inputMultiPicklistValueFromFlow
  ) {
    List<String> outputStringList = new List<String>();

    for (String stringIteration : inputMultiPicklistValueFromFlow) {
      outputStringList.add(stringIteration.replace(';', '<br />'));
    }

    return outputStringList;
  }
}