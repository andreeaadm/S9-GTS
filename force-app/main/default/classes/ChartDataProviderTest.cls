@isTest
public class ChartDataProviderTest {
  @isTest
  static void getOptions_null() {
    Test.startTest();
    final ChartDataProvider aChartDataProvider = new ChartDataProviderMock();
    ChartDataProvider.ChartOption options = aChartDataProvider.getOptions(null);
    Test.stopTest();
    System.assertEquals(
      TEST_OPTIONS,
      options,
      'expecting valid options from ChartDataProviderMock'
    );
  }

  @isTest
  static void testGetData() {
    Test.startTest();
    final ChartDataProvider aChartDataProvider = new ChartDataProviderMock();
    final List<ChartDataProvider.ChartData> chartDatas = aChartDataProvider.getData(
      '10'
    );
    Test.stopTest();
    System.assertEquals(
      TEST_LABELS,
      chartDatas[0].labels,
      'chartDatas.label must equals ' + TEST_LABELS
    );
    System.assertEquals(
      TEST_DATA,
      chartDatas[0].detail,
      'chartDatas.detail must equals ' + TEST_DATA
    );
    System.assertEquals(
      TEST_COLOR,
      chartDatas[0].bgColor,
      'chartDatas.bgColor must equals ' + TEST_COLOR
    );
  }

  public class ChartDataProviderMock extends ChartDataProvider {
    public override ChartDataProvider.ChartOption getOptions(
      final Object parameter
    ) {
      return TEST_OPTIONS;
    }
    public override List<ChartDataProvider.ChartData> getData(
      final Object parameter
    ) {
      final List<ChartDataProvider.ChartData> chartDatas = new List<ChartDataProvider.ChartData>();
      ChartDataProvider.ChartData aChartData = new ChartDataProvider.ChartData();
      aChartData.labels = TEST_LABELS;
      aChartData.detail = TEST_DATA;
      aChartData.bgColor = TEST_COLOR;
      chartDatas.add(aChartData);
      return chartDatas;
    }
  }
  public static final ChartDataProvider.ChartOption TEST_OPTIONS = new ChartDataProvider.ChartOption(
    'label',
    'value',
    'fieldId',
    'type',
    new List<ChartDataProvider.ChartOption>{
      new ChartDataProvider.ChartOption('Option 1', '1'),
      new ChartDataProvider.ChartOption(
        'Option 2',
        '2',
        new ChartDataProvider.ChartOption(
          'option2label',
          'option2value',
          'option2fieldId',
          'option2type',
          new List<ChartDataProvider.ChartOption>{
            new ChartDataProvider.ChartOption('Option 2\'s Option 1', '21'),
            new ChartDataProvider.ChartOption('Option 2\'s Option 2', '22')
          }
        )
      ),
      new ChartDataProvider.ChartOption(
        'Option 3',
        '3',
        new ChartDataProvider.ChartOption()
      )
    }
  );
  public static final List<String> TEST_LABELS = new List<String>{ 'test' };
  public static final List<Decimal> TEST_DATA = new List<Decimal>{ 42 };
  public static final String TEST_COLOR = 'test';
}