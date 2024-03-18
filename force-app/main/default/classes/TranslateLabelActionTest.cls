@isTest
public with sharing class TranslateLabelActionTest {
  @isTest
  static void testTranslateLabelAction() {
    List<TranslateLabelAction.TranslateLabelRequest> requests = new List<TranslateLabelAction.TranslateLabelRequest>();
    TranslateLabelAction.TranslateLabelRequest request = new TranslateLabelAction.TranslateLabelRequest();
    request.languageToTranslateTo = 'bn';
    request.labelToTranslate = 'Submit_a_test_request';
    requests.add(request);

    Test.startTest();
    List<TranslateLabelAction.TranslateLabelResult> results = TranslateLabelAction.translateLabels(
      requests
    );
    Test.stopTest();
    System.assertEquals(1, results.size(), 'There should be one result');
    TranslateLabelAction.TranslateLabelResult result = results[0];
    System.assertNotEquals(
      null,
      result.translatedLabel,
      'String should not be null'
    );
  }
}