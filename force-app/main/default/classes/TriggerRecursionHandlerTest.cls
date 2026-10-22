@isTest
public class TriggerRecursionHandlerTest {

    @isTest
    static void testOpportunityTriggerRunningFlag() {
        // Verify default value
        System.assertEquals(false, TriggerRecursionHandler.isOpportunityTriggerRunning);

        // Update the flag
        TriggerRecursionHandler.isOpportunityTriggerRunning = true;

        // Verify updated value
        System.assertEquals(true, TriggerRecursionHandler.isOpportunityTriggerRunning);
    }
}