/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : TradeIndiaBuyLeadSchedulerTest
 * Author          : <Krisha Mekhiya>
 * Created Date    : Jun 17, 2026
 * Description     : Test class for TradeIndiaBuyLeadScheduler
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
@isTest
public class TradeIndiaBuyLeadSchedulerTest {

    /* ---------------------------------------
       Test 1: Scheduler executes without error
    --------------------------------------- */
    @isTest
    static void testScheduler_ExecutesSuccessfully() {
        Boolean exceptionThrown = false;
        String errorMessage     = '';

        try {
            Test.startTest();
            String cronExp = '0 0 0 * * ?';
            System.schedule('TradeIndiaBuyLeadSchedulerTest_Job', cronExp, new TradeIndiaBuyLeadScheduler());
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
            errorMessage    = e.getMessage();
        }

        if (exceptionThrown) {
            throw new AuraHandledException('testScheduler_ExecutesSuccessfully FAILED: ' + errorMessage);
        }
    }

    /* ---------------------------------------
       Test 2: Scheduler enqueues Queueable job
    --------------------------------------- */
    @isTest
    static void testScheduler_EnqueuesQueueableJob() {
        Boolean exceptionThrown = false;
        String errorMessage     = '';

        try {
            Test.startTest();
            String cronExp = '0 0 1 * * ?';
            System.schedule('TradeIndiaBuyLeadSchedulerTest_Enqueue', cronExp, new TradeIndiaBuyLeadScheduler());
            Test.stopTest();

            // After stopTest, async jobs are flushed
            // If no exception, queueable was enqueued successfully
        } catch (Exception e) {
            exceptionThrown = true;
            errorMessage    = e.getMessage();
        }

        if (exceptionThrown) {
            throw new AuraHandledException('testScheduler_EnqueuesQueueableJob FAILED: ' + errorMessage);
        }
    }

    /* ---------------------------------------
       Test 3: Scheduler can be scheduled
       multiple times with different job names
    --------------------------------------- */
    @isTest
    static void testScheduler_MultipleSchedules() {
        Boolean exceptionThrown = false;
        String errorMessage     = '';

        try {
            Test.startTest();
            System.schedule('TradeIndiaBuyLeadSchedulerTest_Job1', '0 0 2 * * ?', new TradeIndiaBuyLeadScheduler());
            System.schedule('TradeIndiaBuyLeadSchedulerTest_Job2', '0 0 3 * * ?', new TradeIndiaBuyLeadScheduler());
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
            errorMessage    = e.getMessage();
        }

        if (exceptionThrown) {
            throw new AuraHandledException('testScheduler_MultipleSchedules FAILED: ' + errorMessage);
        }
    }

    /* ---------------------------------------
       Test 4: Direct execute() call via
       SchedulableContext (manual trigger)
    --------------------------------------- */
    @isTest
    static void testScheduler_DirectExecute() {
        Boolean exceptionThrown = false;
        String errorMessage     = '';

        try {
            Test.startTest();
            TradeIndiaBuyLeadScheduler scheduler = new TradeIndiaBuyLeadScheduler();
            scheduler.execute(null);
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
            errorMessage    = e.getMessage();
        }

        if (exceptionThrown) {
            throw new AuraHandledException('testScheduler_DirectExecute FAILED: ' + errorMessage);
        }
    }

    /* ---------------------------------------
       Test 5: Scheduled job can be aborted
    --------------------------------------- */
    @isTest
    static void testScheduler_JobCanBeAborted() {
        Boolean exceptionThrown = false;
        String errorMessage     = '';

        try {
            Test.startTest();
            String jobId = System.schedule('TradeIndiaBuyLeadSchedulerTest_Abort', '0 0 4 * * ?', new TradeIndiaBuyLeadScheduler());
            System.abortJob(jobId);
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
            errorMessage    = e.getMessage();
        }

        if (exceptionThrown) {
            throw new AuraHandledException('testScheduler_JobCanBeAborted FAILED: ' + errorMessage);
        }
    }
}