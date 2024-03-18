@isTest
public with sharing class icare_FlowHelperTest {
  @isTest
  public static void confirmStringFromating() {
    List<String> listOfMultiPicklistStrings = new List<String>();
    listOfMultiPicklistStrings.add('Value1;Value2;Value3');
    listOfMultiPicklistStrings.add('Value4;Value5;Value6');
    listOfMultiPicklistStrings.add('Value7;Value8;Value9');

    String value1ExpectedOutput = 'Value1<br />Value2<br />Value3';

    List<String> outputFromMethod = icare_FlowHelper.ConvertMultiPicklistHTML(
      listOfMultiPicklistStrings
    );

    Assert.areEqual(
      outputFromMethod[0].contains(value1ExpectedOutput),
      true,
      'The output should return a List<String>. Index 0 should return : (' +
      value1ExpectedOutput +
      ')'
    );
  }
}