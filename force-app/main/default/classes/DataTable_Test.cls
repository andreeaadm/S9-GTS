@isTest
public with sharing class DataTable_Test {
  // Without navMixinPageRefs
  @isTest
  private static void Test_1_1() {
    Test.startTest();
    DataTable.Table table = new DataTable.Table();
    table.columns = new List<DataTable.Column>{
      new DataTable.Column('test1', 'test2')
    };
    table.rows = new List<DataTable.Row>{
      new DataTable.Row(
        'test',
        new List<DataTable.Cell>{
          new DataTable.Cell('test', 'test', false, '', 'test1'),
          new DataTable.Cell('test', 'test', false, '', 'test2')
        }
      )
    };
    Test.stopTest();
    System.assert(table.rows.size() > 0);
  }

  // With navMixinPageRefs and using the overloaded Table constructor
  @isTest
  private static void Test_1_2() {
    Test.startTest();
    List<DataTable.Column> columns = new List<DataTable.Column>{
      new DataTable.Column('test1', 'test2', 'ASC')
    };
    List<DataTable.Row> rows = new List<DataTable.Row>{
      new DataTable.Row(
        'test',
        new List<DataTable.Cell>{
          new DataTable.Cell(
            'test',
            'test',
            new Map<String, Object>(),
            false,
            false,
            false,
            '',
            '',
            '',
            'test1'
          ),
          new DataTable.Cell(
            'test',
            'test',
            new Map<String, Object>(),
            false,
            false,
            false,
            '',
            '',
            '',
            'test2'
          )
        }
      )
    };
    DataTable.Table table = new DataTable.Table(columns, rows, 'test');
    Test.stopTest();
    System.assert(table.rows.size() > 0);
  }

  // With disabled attribute set
  @isTest
  private static void Test_1_3() {
    Test.startTest();
    List<DataTable.Column> columns = new List<DataTable.Column>{
      new DataTable.Column('test1', 'test2')
    };
    List<DataTable.Row> rows = new List<DataTable.Row>{
      new DataTable.Row(
        'test',
        new List<DataTable.Cell>{
          new DataTable.Cell(
            'test',
            'test',
            new Map<String, Object>(),
            false,
            false,
            false,
            '',
            '',
            '',
            'test1',
            true
          ),
          new DataTable.Cell(
            'test',
            'test',
            new Map<String, Object>(),
            false,
            false,
            false,
            '',
            '',
            '',
            'test2',
            true
          )
        }
      )
    };
    DataTable.Table table = new DataTable.Table(columns, rows, 'test');
    Test.stopTest();
    System.assert(table.rows.size() > 0);
  }

  // Testing another Column constructor overload
  @isTest
  private static void Test_1_4() {
    Test.startTest();
    List<DataTable.Column> columns = new List<DataTable.Column>{
      new DataTable.Column('test1', 'test2', false)
    };
    List<DataTable.Row> rows = new List<DataTable.Row>{
      new DataTable.Row(
        'test',
        new List<DataTable.Cell>{
          new DataTable.Cell(
            'test',
            'test',
            new Map<String, Object>(),
            false,
            false,
            false,
            '',
            '',
            '',
            'test1',
            true
          ),
          new DataTable.Cell(
            'test',
            'test',
            new Map<String, Object>(),
            false,
            false,
            false,
            '',
            '',
            '',
            'test2',
            true
          )
        }
      )
    };
    DataTable.Table table = new DataTable.Table(columns, rows, 'test');
    Test.stopTest();
    System.assert(table.rows.size() > 0);
  }

  // Testing another Column constructor overload
  @isTest
  private static void Test_1_5() {
    Test.startTest();
    List<DataTable.Column> columns = new List<DataTable.Column>{
      new DataTable.Column('test1', true)
    };
    List<DataTable.Row> rows = new List<DataTable.Row>{
      new DataTable.Row(
        'test',
        new List<DataTable.Cell>{
          new DataTable.Cell(
            'test',
            'test',
            new Map<String, Object>(),
            false,
            false,
            false,
            '',
            '',
            '',
            'test1',
            true
          ),
          new DataTable.Cell(
            'test',
            'test',
            new Map<String, Object>(),
            false,
            false,
            false,
            '',
            '',
            '',
            'test2',
            true
          )
        }
      )
    };
    DataTable.Table table = new DataTable.Table(columns, rows, 'test');
    Test.stopTest();
    System.assert(table.rows.size() > 0);
  }

  // Testing another Cell constructor overload
  @isTest
  private static void Test_1_6() {
    Test.startTest();
    List<DataTable.Column> columns = new List<DataTable.Column>{
      new DataTable.Column('test1', true)
    };
    List<DataTable.Row> rows = new List<DataTable.Row>{
      new DataTable.Row(
        'test',
        new List<DataTable.Cell>{ new DataTable.Cell('test', 'test', 'test') }
      )
    };
    DataTable.Table table = new DataTable.Table(columns, rows, 'test');
    Test.stopTest();
    System.assert(table.rows.size() > 0);
  }

  // Testing more Cell constructor overloads
  @isTest
  private static void Test_1_7() {
    Test.startTest();
    List<DataTable.Column> columns = new List<DataTable.Column>{
      new DataTable.Column('test1', true)
    };
    List<DataTable.Row> rows = new List<DataTable.Row>{
      new DataTable.Row(
        'test',
        new List<DataTable.Cell>{
          new DataTable.Cell('test', 'test', true, false, null, 'test'),
          new DataTable.Cell(
            'test',
            'test',
            false,
            true,
            new Map<String, String>{ 'label' => 'label', 'value' => 'value' },
            'test'
          )
        }
      )
    };
    DataTable.Table table = new DataTable.Table(columns, rows, 'test');
    Test.stopTest();
    System.assert(table.rows.size() > 0);
  }

  @isTest
  private static void testActionCellWithCustomClass() {
    Test.startTest();
    DataTable.Cell cell = new DataTable.Cell(
      'action',
      'view',
      null,
      true,
      true,
      false,
      'view',
      'view',
      '',
      '',
      false,
      'custom-class'
    );
    Test.stopTest();
    System.assertEquals('clickable custom-class', cell.styleClass);
  }

  @isTest
  private static void testNotActionCellWithCustomClass() {
    Test.startTest();
    DataTable.Cell cell = new DataTable.Cell(
      'action',
      'view',
      null,
      false,
      true,
      false,
      'view',
      'view',
      '',
      '',
      false,
      'custom-class'
    );
    Test.stopTest();
    System.assertEquals('custom-class', cell.styleClass);
  }

  @isTest
  private static void testActionCellWithoutCustomClass() {
    Test.startTest();
    DataTable.Cell cell = new DataTable.Cell(
      'action',
      'view',
      null,
      true,
      true,
      false,
      'view',
      'view',
      '',
      '',
      false,
      null
    );
    Test.stopTest();
    System.assertEquals('clickable', cell.styleClass);
  }

  @isTest
  private static void testNotActionCellWithoutCustomClass() {
    Test.startTest();
    DataTable.Cell cell = new DataTable.Cell(
      'action',
      'view',
      null,
      false,
      true,
      false,
      'view',
      'view',
      '',
      '',
      false,
      null
    );
    Test.stopTest();
    System.assertEquals('', cell.styleClass);
  }

  @isTest
  private static void testCellDifferentConstructorWithoutCustomClass() {
    Test.startTest();
    DataTable.Cell cell = new DataTable.Cell('action', 'view', 'View');
    Test.stopTest();
    System.assertEquals(null, cell.styleClass);
  }
}