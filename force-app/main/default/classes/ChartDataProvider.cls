/**
 * @author lwcc
 * @date 2020
 *
 * @description Chart Data Provider abstract class. It define the type the chartBuilder component can use to get data
 */
global inherited sharing abstract class ChartDataProvider {
  /*******************************************************************************************************
   * @description serve as an additional constructor when the classes are instanciated with type forName
   * @param initParameter any data structure the subclass requires
   */
  global abstract ChartOption getOptions(final Object parameter);

  global class ChartOption {
    public ChartOption() {
    }
    // Construct an option.
    public ChartOption(String label, String value) {
      this.label = label;
      this.value = value;
    }
    // Construct an option with a list of dependant selectors.
    public ChartOption(String label, String value, ChartOption selector) {
      this.label = label;
      this.value = value;
      this.selector = selector;
    }
    // Construct a selector of options.
    public ChartOption(
      String label,
      String value,
      String fieldId,
      String type,
      List<ChartOption> options
    ) {
      this.label = label;
      this.value = value;
      this.fieldId = fieldId;
      this.type = type;
      this.options = options;
    }

    @AuraEnabled
    global String label;

    @AuraEnabled
    global String value;

    @AuraEnabled
    global List<ChartOption> options;
    @AuraEnabled
    global ChartOption selector;

    @AuraEnabled
    global String type;

    @AuraEnabled
    global String fieldId;
  }

  /*******************************************************************************************************
   * @description allow to get the data from the real sub class
   * @return List<ChartData> the list of chart data needed to display the graph
   */
  global abstract List<ChartData> getData(Object parameter);

  /**
   * @description Chart Data Wrapper class
   */
  global class ChartData {
    /*******************************************************************************************************
     * @description contains the label for this data
     */
    @AuraEnabled
    global List<String> labels;

    /*******************************************************************************************************
     * @description contains the values for this data
     */
    @AuraEnabled
    global List<Object> detail;

    /*******************************************************************************************************
     * @description color to use to display the valueSet (if empty uses the default slds palette). RGBA, RBB, or hex strings
     */
    @AuraEnabled
    global String bgColor;

    /*******************************************************************************************************
     * @description success, but no comparisson since detail all zero, so treat as empty for pie chart.
     */
    @AuraEnabled
    global Boolean allZero;
  }
}