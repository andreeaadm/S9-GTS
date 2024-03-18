public class TranslateLabelAction {
  @InvocableMethod(
    label='Get Translated Label'
    description='Get Translated Label'
  )
  public static List<TranslateLabelResult> translateLabels(
    List<TranslateLabelRequest> requests
  ) {
    List<TranslateLabelResult> results = new List<TranslateLabelResult>();
    for (TranslateLabelRequest request : requests) {
      results.add(translateLabel(request));
    }
    return results;
  }

  private static TranslateLabelResult translateLabel(
    TranslateLabelRequest request
  ) {
    TranslateLabelResult translatedLabelResult = new TranslateLabelResult();
    translatedLabelResult.translatedLabel = System.Label.get(
      '',
      request.labelToTranslate,
      request.languageToTranslateTo
    );
    return translatedLabelResult;
  }

  public class TranslateLabelRequest {
    @InvocableVariable(required=true)
    public String languageToTranslateTo;

    @InvocableVariable(required=true)
    public String labelToTranslate;
  }

  public class TranslateLabelResult {
    @InvocableVariable
    public String translatedLabel;
  }
}