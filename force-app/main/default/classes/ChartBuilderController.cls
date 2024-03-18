/**
 * @author lwcc
 * @date 2020
 *
 * @description Chart Builder LWC Controller class. Proxy for the ChartDataProvider
 */
public inherited sharing class ChartBuilderController {
  /*******************************************************************************************************
   * @description Not used for this class
   * @param chartDataProviderType String containing the ChartDataProvider type to instanciate to get the data
   * @param ctx Object to pass the context to get the data
   */
  @AuraEnabled
  public static ChartDataProvider.ChartOption getChartOptions(
    final String chartDataProviderType,
    final Object ctx
  ) {
    try {
      final ChartDataProvider aChartDataProvider = (ChartDataProvider) Type.forName(
          chartDataProviderType
        )
        .newInstance();
      return aChartDataProvider.getOptions(ctx);
    } catch (Exception ex) {
      AuraHandledException ahex = new AuraHandledException(ex.getMessage());
      ahex.setMessage(ex.getMessage());
      throw ahex;
    }
  }
  /*******************************************************************************************************
   * @description Not used for this class
   * @param chartDataProviderType String containing the ChartDataProvider type to instanciate to get the data
   * @param ctx Object to pass the context to get the data
   */
  @AuraEnabled
  public static List<ChartDataProvider.ChartData> getChartData(
    final String chartDataProviderType,
    final Object ctx
  ) {
    try {
      final ChartDataProvider aChartDataProvider = (ChartDataProvider) Type.forName(
          chartDataProviderType
        )
        .newInstance();
      return aChartDataProvider.getData(ctx);
    } catch (Exception ex) {
      AuraHandledException ahex = new AuraHandledException(ex.getMessage());
      ahex.setMessage(ex.getMessage());
      throw ahex;
    }
  }
}