/**
 * @author lwcc
 * @date 2020
 *
 * @description SOQL Data Provider class. It allow to get ChartData using an SOQL query
 */
public inherited sharing virtual class SOQLDataProvider extends ChartDataProvider {
  private static final String SOQL_SECURITY_ENFORCED = 'WITH SECURITY_ENFORCED';
  private static final String SOQL_LIMIT_STATEMENT = 'LIMIT';
  private static final String LABEL_ALIAS = 'label';
  private static final String VALUE_ALIAS = 'value';
  public static final String UNDEFINED_RECORDID = '\'xxxxxxxxxxxxxxx\'';

  public static final String QUERY_NULL_EXCEPTION = 'Query is null';
  public static final String QUERY_WITHOUT_LABEL_EXCEPTION = 'Query must contains "label" alias';
  public static final String QUERY_WITHOUT_VALUE_EXCEPTION = 'Query must contains "value" alias';
  public static final String QUERY_WITHOUT_LIMIT_EXCEPTION =
    'Query must contains "' +
    SOQL_LIMIT_STATEMENT +
    '" statement';
  public static final String QUERY_WITHOUT_SECURITY_ENFORCED_EXCEPTION =
    'Query must contains "' +
    SOQL_SECURITY_ENFORCED +
    '"';

  /**
   * getOptions is yet to provide a directory of queries for calling getData with.
   * @return Map<String, Object>: returns null
   */
  public virtual override ChartDataProvider.ChartOption getOptions(
    final Object parameter
  ) {
    return null;
  }

  /*******************************************************************************************************
   * @description return the data structured by the SOQL query
   * @return List<ChartData> the list of chart data needed to display the graph
   */
  public virtual override List<ChartDataProvider.ChartData> getData(
    final Object parameter
  ) {
    String query = (String) parameter;
    if (String.isBlank(query)) {
      throw new SOQLDataProviderException(QUERY_NULL_EXCEPTION);
    }

    if (!query.containsIgnoreCase(' ' + LABEL_ALIAS)) {
      throw new SOQLDataProviderException(QUERY_WITHOUT_LABEL_EXCEPTION);
    }

    if (!query.containsIgnoreCase(' ' + VALUE_ALIAS)) {
      throw new SOQLDataProviderException(QUERY_WITHOUT_VALUE_EXCEPTION);
    }

    if (!query.containsIgnoreCase(' ' + SOQL_LIMIT_STATEMENT + ' ')) {
      throw new SOQLDataProviderException(QUERY_WITHOUT_LIMIT_EXCEPTION);
    }

    if (!query.containsIgnoreCase(' ' + SOQL_SECURITY_ENFORCED)) {
      throw new SOQLDataProviderException(
        QUERY_WITHOUT_SECURITY_ENFORCED_EXCEPTION
      );
    }

    // When building the chart in the app builder and using :recordId in the query
    // The context is not set and :recordId is undefined
    // In this case we can't get not data but it is still possible to build the chart in the App Builder
    if (query.contains(UNDEFINED_RECORDID)) {
      return new List<ChartDataProvider.ChartData>();
    }

    final ChartDataProvider.ChartData aChartData = new ChartDataProvider.ChartData();
    aChartData.labels = new List<String>();
    aChartData.detail = new List<Object>();

    for (AggregateResult aResult : Database.query(query)) {
      String label = '' + aResult.get(LABEL_ALIAS);
      if (
        aResult.get(LABEL_ALIAS) != null &&
        aResult.get(LABEL_ALIAS) instanceof Date
      ) {
        label = ((Date) aResult.get(LABEL_ALIAS)).format();
      }

      aChartData.labels.add(label);
      aChartData.detail.add(aResult.get(VALUE_ALIAS));
    }

    return new List<ChartDataProvider.ChartData>{ aChartData };
  }

  public class SOQLDataProviderException extends Exception {
  }
}