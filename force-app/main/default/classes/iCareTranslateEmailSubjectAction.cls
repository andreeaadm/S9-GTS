global class iCareTranslateEmailSubjectAction {
  @InvocableMethod(label='Translate Email Subject')
  global static List<TranslateEmailSubjectActionResult> translatedEmailSubjects(
    List<TranslateEmailSubjectRequest> requests
  ) {
    List<TranslateEmailSubjectActionResult> results = new List<TranslateEmailSubjectActionResult>();
    for (TranslateEmailSubjectRequest request : requests) {
      results.add(translateEmailSubject(request));
    }
    return results;
  }

  public static TranslateEmailSubjectActionResult translateEmailSubject(
    TranslateEmailSubjectRequest request
  ) {
    TranslateEmailSubjectActionResult result = new TranslateEmailSubjectActionResult();
    String translatedValue;

    if (String.isBlank(request.jobSubject)) {
      result.translatedValue = '';
      return result;
    }

    if (
      request.jobSubject == 'Job Submitted (iCare)' ||
      request.jobSubject == 'Job Submitted (Ops System)'
    ) {
      translatedValue = request.jobSubject == 'Job Submitted (iCare)'
        ? translateLabelValue(
            'iCareStatusEmailTemplateSubjectSumitted',
            request.language
          ) +
          ' ' +
          request.jobId +
          '  ' +
          translateLabelValue(
            'iCareStatusEmailTemplateSubjectSumitted_2',
            request.language
          )
        : '';
    } else {
      translatedValue = request.jobSubject == 'Sample Received'
        ? translateLabelValue(
            'iCare_Sample_Received_Email_Subject',
            request.language
          ) +
          ' ' +
          request.jobId
        : request.jobSubject == 'Test in Progress'
            ? translateLabelValue(
                'iCare_Test_In_Progress_Email_Subject',
                request.language
              ) +
              ' ' +
              request.jobId
            : request.jobSubject == 'Test Report Issued'
                ? translateLabelValue(
                    'iCare_Report_Issued_Email_Subject',
                    request.language
                  ) +
                  ' ' +
                  request.jobId
                : request.jobSubject == 'Cancelled'
                    ? translateLabelValue(
                        'iCare_Job_Cancelled_Email_Subject_1',
                        request.language
                      ) +
                      ' ' +
                      request.jobId +
                      ' ' +
                      translateLabelValue(
                        'iCare_Job_Cancelled_Email_Subject_2',
                        request.language
                      )
                    : request.jobSubject == 'Pending'
                        ? translateLabelValue(
                            'iCare_Job_Pending_Email_Subject',
                            request.language
                          ) +
                          ' ' +
                          request.jobId
                        : request.jobSubject == 'Special Remark'
                            ? translateLabelValue(
                                'iCare_Special_Remarks_Subject_Email_Template',
                                request.language
                              ) +
                              ' ' +
                              request.jobId
                            : '';
    }

    result.translatedValue = translatedValue;
    return result;
  }

  global class TranslateEmailSubjectActionResult {
    @InvocableVariable
    global String translatedValue;
  }

  global class TranslateEmailSubjectRequest {
    @InvocableVariable(
      label='Job Subject'
      description='Status of the Job to be translated'
      required=true
    )
    global String jobSubject;

    @InvocableVariable(
      label='User Language'
      description='API name of the language to translate to'
      required=true
    )
    global String language;

    @InvocableVariable(
      label='Job Id'
      description='Id of the job to be incorporated in to the status'
    )
    global String jobId;
  }

  public static string translateLabelValue(
    String labelToTranslate,
    String languageToTranslateTo
  ) {
    String translatedLabel = System.Label.get(
      '',
      labelToTranslate,
      languageToTranslateTo
    );
    return translatedLabel;
  }
}