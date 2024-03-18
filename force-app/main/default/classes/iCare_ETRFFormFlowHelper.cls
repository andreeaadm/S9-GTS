/**
 *  @author  Globant
 *  @since   October 2023
 *  @description ETRF Form Flow Helper class to support any generic flow actions (e.g. flow custom error mesage handling)
 **/

public with sharing class iCare_ETRFFormFlowHelper {
  private static final String NEW_LINE_CHARACTER = '\n';
  private static final String COMMA_CHARACTER = ',';
  private static final String UNDERSCORE_CHARACTER = '_';
  private static final List<String> SECTION_LABELS = new List<String>{
    'iCare_Section_Service_Term',
    'iCare_Section_Applicant_Information',
    'iCare_Section_Invoicing_Information',
    'iCare_Section_Sample_and_Report_Information',
    'iCare_Section_Test_Selection',
    'iCare_Section_Agency_Information'
  };
  //Used to store and check minimum field length requirements
  private static final Map<String, Integer> MIN_LENGTH_VALIDATIONS = new Map<String, Integer>{
    'iCare_Applicant_Contact_Person_Name__c' => 3,
    'iCare_Invoiced_Co_Contact_Person_Name__c' => 3,
    'iCare_Agency_Contact_Person_Name__c' => 3,
    'iCare_Agency_Telephone_External__c' => 5,
    'iCare_Applicant_Telephone_External__c' => 5,
    'iCare_Invoiced_Co_Telephone_External__c' => 5,
    'iCare_Fiber_Composition__c' => 1
  };

  // store Number error for each section
  private static Map<String, List<String>> minimumLengthValidations = new Map<String, List<String>>();

  public class ETRFFormFlowHelperRequest {
    @InvocableVariable(
      label='Action'
      description='Action to perform'
      required=true
    )
    public String action;
    @InvocableVariable(
      label='Job Request Record'
      description='Record to be processed'
      required=false
    )
    public icare_Job_Request__c jobRequest;
    @InvocableVariable(
      label='User Region'
      description='The region of the user running the flow'
      required=false
    )
    public String userRegion;
  }

  public class ETRFFormFlowHelperResponse {
    @InvocableVariable
    public String errorMessage;
    @InvocableVariable
    public String serviceTermErrorMessage;
    @InvocableVariable
    public String applicantInformationErrorMessage;
    @InvocableVariable
    public String invoicingInformationErrorMessage;
    @InvocableVariable
    public String sampleAndReportInformationErrorMessage;
    @InvocableVariable
    public String testSelectionErrorMessage;
    @InvocableVariable
    public String agencyInformationErrorMessage;
  }

  /**
   * @description Invocable method called from flows - allows to execute various actions based on action given
   * @param requests (List<ETRFFormFlowHelperRequest>) - Requests to process
   *
   * @return List<ETRFFormFlowHelperResponse> - Responses returned
   */
  @InvocableMethod(
    label='ETRF Form Flow Helper'
    description='Runs specified action for generic processing in flows'
  )
  public static List<ETRFFormFlowHelperResponse> process(
    List<ETRFFormFlowHelperRequest> flowItems
  ) {
    List<ETRFFormFlowHelperResponse> responses = new List<ETRFFormFlowHelperResponse>();

    for (ETRFFormFlowHelperRequest flowItem : flowItems) {
      ETRFFormFlowHelperResponse response = new ETRFFormFlowHelperResponse();
      if (
        flowItem.action.toLowerCase() == 'check-required-fields-are-populated'
      ) {
        verifyRequiredFieldsPopulated(flowItem, response);
      } else {
        response.errorMessage =
          System.Label.iCare_ETRF_Form_Apex_Error + flowItem.action;
      }
      responses.add(response);
    }

    return responses;
  }

  /**
   * @description Method to check all required fields in field sets are populated given a job request record & region
   * @param request (ETRFFormFlowHelperRequest) - Request to process
   * @param response (ETRFFormFlowHelperResponse) - Response to generate
   *
   */
  private static void verifyRequiredFieldsPopulated(
    ETRFFormFlowHelperRequest request,
    ETRFFormFlowHelperResponse response
  ) {
    Map<String, String> sectionValueWithAPINames = new Map<String, String>();
    Map<String, List<String>> sectionLabelsWithRequiredFields = new Map<String, List<String>>();
    Map<String, String> requiredFieldsNameWithLabel = new Map<String, String>();
    List<String> englishValues = new List<String>();

    //Changing converting Turkish value to english
    String userRegion = request.userRegion == 'Türkiye'
      ? 'Turkey'
      : request.userRegion;

    //translate label values to english
    for (String sectionLabel : SECTION_LABELS) {
      englishValues.add(System.Label.get(null, sectionLabel, 'en_US'));
    }

    //Construct field set API name strings
    for (String sectionValue : englishValues) {
      String sectionInfo = '';
      for (String sectionInfoWord : sectionValue.split(' ')) {
        sectionInfo += sectionInfoWord + UNDERSCORE_CHARACTER;
      }

      //remove trailing underscore
      sectionInfo = sectionInfo.substring(0, sectionInfo.length() - 1);
      sectionValueWithAPINames.put(
        sectionValue,
        userRegion +
        UNDERSCORE_CHARACTER +
        sectionInfo
      );
    }

    //Get all required fields
    for (String sectionLabel : sectionValueWithAPINames.keyset()) {
      System.debug('sectionLabel: ' + sectionLabel);
      String fieldSetAPIName = sectionValueWithAPINames.get(sectionLabel);
      Schema.FieldSet fieldSet = Schema.SObjectType.icare_Job_Request__c.fieldSets.getMap()
        .get(fieldSetAPIName);
      for (Schema.FieldSetMember fsm : fieldSet.getFields()) {
        System.debug('field: ' + fsm);
        if (fsm.getRequired() == true) {
          String fieldName = String.valueOf(fsm.getSObjectField());
          String fieldLabel = fsm.getLabel();
          requiredFieldsNameWithLabel.put(fieldName, fieldLabel);

          if (sectionLabelsWithRequiredFields.get(sectionLabel) == null) {
            sectionLabelsWithRequiredFields.put(
              sectionLabel,
              new List<String>{ fieldName }
            );
          } else {
            List<String> tempList = sectionLabelsWithRequiredFields.get(
              sectionLabel
            );
            tempList.add(fieldName);
            sectionLabelsWithRequiredFields.put(sectionLabel, tempList);
          }
        }

        if (
          MIN_LENGTH_VALIDATIONS.get(String.valueOf(fsm.getSObjectField())) !=
          null &&
          !String.isBlank(
            (String) request.jobRequest.get(
              String.valueOf(fsm.getSObjectField())
            )
          )
        ) {
          String fieldName = String.valueOf(fsm.getSObjectField());
          String fieldValue = (String) request.jobRequest.get(
            String.valueOf(fsm.getSObjectField())
          );
          String fieldLabel = fsm.getLabel().remove('*').trim();
          String characterLengthLabel = System.Label.iCare_ETRF_Minimum_Length_Requirement;
          String characterError = '';

          System.debug(
            'fieldName: ' +
            fieldName +
            ' fieldLabel: ' +
            fieldLabel +
            ' Length: ' +
            fieldValue.length() +
            ' Min Length: ' +
            MIN_LENGTH_VALIDATIONS.get(fieldName)
          );

          if (fieldValue.length() < MIN_LENGTH_VALIDATIONS.get(fieldName)) {
            characterError =
              NEW_LINE_CHARACTER +
              fieldLabel +
              ' ' +
              characterLengthLabel +
              ' ' +
              MIN_LENGTH_VALIDATIONS.get(fieldName);
            if (minimumLengthValidations.get(sectionLabel) != null) {
              minimumLengthValidations.get(sectionLabel).add(characterError);
              System.debug(
                'Section: ' +
                sectionLabel +
                ' list: ' +
                minimumLengthValidations.get(sectionLabel)
              );
            } else {
              if (sectionLabelsWithRequiredFields.get(sectionLabel) == null) {
                sectionLabelsWithRequiredFields.put(
                  sectionLabel,
                  new List<String>{ fieldName }
                );
              }

              minimumLengthValidations.put(
                sectionLabel,
                new List<String>{ characterError }
              );
              System.debug(
                'Section: ' +
                sectionLabel +
                ' list: ' +
                minimumLengthValidations.get(sectionLabel)
              );
            }
          }
        }
      }
    }

    //Check if required fields are populated on the Job Request record and assign error messages if not
    for (String sectionLabel : sectionLabelsWithRequiredFields.keyset()) {
      List<String> fieldNames = sectionLabelsWithRequiredFields.get(
        sectionLabel
      );
      for (String fieldName : fieldNames) {
        if (
          request.jobRequest.get(fieldName) == null ||
          request.jobRequest.get(fieldName) == false ||
          String.isBlank((String) request.jobRequest.get(fieldName))
        ) {
          String fieldLabel = requiredFieldsNameWithLabel.get(fieldName)
            .remove('*')
            .trim();
          if (sectionLabel == englishValues[0]) {
            response.serviceTermErrorMessage = response.serviceTermErrorMessage ==
              null
              ? System.Label.iCare_ETRF_Required_Fields +
                NEW_LINE_CHARACTER +
                fieldLabel
              : response.serviceTermErrorMessage + COMMA_CHARACTER + fieldLabel;
          } else if (sectionLabel == englishValues[1]) {
            response.applicantInformationErrorMessage = response.applicantInformationErrorMessage ==
              null
              ? System.Label.iCare_ETRF_Required_Fields +
                NEW_LINE_CHARACTER +
                fieldLabel
              : response.applicantInformationErrorMessage +
                COMMA_CHARACTER +
                fieldLabel;
          } else if (sectionLabel == englishValues[2]) {
            response.invoicingInformationErrorMessage = response.invoicingInformationErrorMessage ==
              null
              ? System.Label.iCare_ETRF_Required_Fields +
                NEW_LINE_CHARACTER +
                fieldLabel
              : response.invoicingInformationErrorMessage +
                COMMA_CHARACTER +
                fieldLabel;
          } else if (sectionLabel == englishValues[3]) {
            response.sampleAndReportInformationErrorMessage = response.sampleAndReportInformationErrorMessage ==
              null
              ? System.Label.iCare_ETRF_Required_Fields +
                NEW_LINE_CHARACTER +
                fieldLabel
              : response.sampleAndReportInformationErrorMessage +
                COMMA_CHARACTER +
                fieldLabel;
          } else if (sectionLabel == englishValues[4]) {
            response.testSelectionErrorMessage = response.testSelectionErrorMessage ==
              null
              ? System.Label.iCare_ETRF_Required_Fields +
                NEW_LINE_CHARACTER +
                fieldLabel
              : response.testSelectionErrorMessage +
                COMMA_CHARACTER +
                fieldLabel;
          } else if (sectionLabel == englishValues[5]) {
            response.agencyInformationErrorMessage = response.agencyInformationErrorMessage ==
              null
              ? System.Label.iCare_ETRF_Required_Fields +
                NEW_LINE_CHARACTER +
                fieldLabel
              : response.agencyInformationErrorMessage +
                COMMA_CHARACTER +
                fieldLabel;
          }
        }
      }
      if (minimumLengthValidations.get(sectionLabel) != null) {
        String errorString = '';
        for (String error : minimumLengthValidations.get(sectionLabel)) {
          errorString = errorString + error;
        }
        if (sectionLabel == englishValues[0]) {
          response.serviceTermErrorMessage = response.serviceTermErrorMessage ==
            null
            ? errorString
            : response.serviceTermErrorMessage + errorString;
        } else if (sectionLabel == englishValues[1]) {
          response.applicantInformationErrorMessage = response.applicantInformationErrorMessage ==
            null
            ? errorString
            : response.applicantInformationErrorMessage + errorString;
        } else if (sectionLabel == englishValues[2]) {
          response.invoicingInformationErrorMessage = response.invoicingInformationErrorMessage ==
            null
            ? errorString
            : response.invoicingInformationErrorMessage + errorString;
        } else if (sectionLabel == englishValues[3]) {
          response.sampleAndReportInformationErrorMessage = response.sampleAndReportInformationErrorMessage ==
            null
            ? errorString
            : response.sampleAndReportInformationErrorMessage + errorString;
        } else if (sectionLabel == englishValues[4]) {
          response.testSelectionErrorMessage = response.testSelectionErrorMessage ==
            null
            ? errorString
            : response.testSelectionErrorMessage + errorString;
        } else if (sectionLabel == englishValues[5]) {
          response.agencyInformationErrorMessage = response.agencyInformationErrorMessage ==
            null
            ? errorString
            : response.agencyInformationErrorMessage + errorString;
        }
      }
    }
  }
}