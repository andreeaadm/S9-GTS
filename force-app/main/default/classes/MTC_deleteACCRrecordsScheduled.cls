global class MTC_deleteACCRrecordsScheduled implements schedulable
{
    global void execute(SchedulableContext sc)
    {
        MTC_deleteACCRrecords b = new MTC_deleteACCRrecords();
        database.executebatch(b);
    }
}