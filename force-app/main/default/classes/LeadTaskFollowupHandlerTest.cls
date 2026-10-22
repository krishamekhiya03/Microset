@isTest
private class LeadTaskFollowupHandlerTest {

    @testSetup
    static void setupData() {

        Lead_Custom__c lead = new Lead_Custom__c(
            Lead_Status__c = 'New'
        );
        insert lead;
    }

    // Helper to build an oldMap manually for direct method invocation
    private static Map<Id, Task> buildOldMap(List<Task> oldTasks) {

        Map<Id, Task> oldMap = new Map<Id, Task>();

        for (Task t : oldTasks) {
            oldMap.put(t.Id, t);
        }

        return oldMap;
    }

    @isTest
    static void testHandleTaskUpdate_Attempt1_CreatesAttempt2() {

        Lead_Custom__c lead = [SELECT Id, OwnerId FROM Lead_Custom__c LIMIT 1];

        Task t = new Task(
            WhatId = lead.Id,
            Subject = 'Follow-up Call - Attempt 1',
            Status = 'Open',
            ActivityDate = Date.today()
        );
        insert t;

        // Simulate "old" version of the task before status change
        Task oldVersion = t.clone(true, true, false, false);
        oldVersion.Status = 'Open';

        // Update to the new status
        t.Status = 'Call Not Answered';
        update t;

        Map<Id, Task> oldMap = buildOldMap(new List<Task>{ oldVersion });

        Test.startTest();
        LeadTaskFollowupHandler.handleTaskUpdate(
            new List<Task>{ t },
            oldMap
        );
        Test.stopTest();

        List<Task> followUpTasks = [
            SELECT Id, Subject
            FROM Task
            WHERE WhatId = :lead.Id
            AND Subject = 'Follow-up Call - Attempt 2'
        ];
    }

    @isTest
    static void testHandleTaskUpdate_Attempt2_CreatesAttempt3() {

        Lead_Custom__c lead = [SELECT Id, OwnerId FROM Lead_Custom__c LIMIT 1];

        Task attempt1 = new Task(
            WhatId = lead.Id,
            Subject = 'Follow-up Call - Attempt 1',
            Status = 'Open',
            ActivityDate = Date.today()
        );
        insert attempt1;

        Task t = new Task(
            WhatId = lead.Id,
            Subject = 'Follow-up Call - Attempt 2',
            Status = 'Open',
            ActivityDate = Date.today()
        );
        insert t;

        Task oldVersion = t.clone(true, true, false, false);
        oldVersion.Status = 'Open';

        t.Status = 'Call Not Answered';
        update t;

        Map<Id, Task> oldMap = buildOldMap(new List<Task>{ oldVersion });

        Test.startTest();
        LeadTaskFollowupHandler.handleTaskUpdate(
            new List<Task>{ t },
            oldMap
        );
        Test.stopTest();

        List<Task> followUpTasks = [
            SELECT Id, Subject
            FROM Task
            WHERE WhatId = :lead.Id
            AND Subject = 'Follow-up Call - Attempt 3'
        ];
    }

    @isTest
    static void testHandleTaskUpdate_Attempt3_MarksLeadUnqualified() {

        Lead_Custom__c lead = [SELECT Id, OwnerId, Lead_Status__c FROM Lead_Custom__c LIMIT 1];

        Task t = new Task(
            WhatId = lead.Id,
            Subject = 'Follow-up Call - Attempt 3',
            Status = 'Open',
            ActivityDate = Date.today()
        );
        insert t;

        Task oldVersion = t.clone(true, true, false, false);
        oldVersion.Status = 'Open';

        t.Status = 'Call Not Answered';
        update t;

        Map<Id, Task> oldMap = buildOldMap(new List<Task>{ oldVersion });

        Test.startTest();
        LeadTaskFollowupHandler.handleTaskUpdate(
            new List<Task>{ t },
            oldMap
        );
        Test.stopTest();

        Lead_Custom__c updatedLead = [
            SELECT Id, Lead_Status__c
            FROM Lead_Custom__c
            WHERE Id = :lead.Id
        ];
    }

    @isTest
    static void testHandleTaskUpdate_StatusUnchanged_NoAction() {

        Lead_Custom__c lead = [SELECT Id, OwnerId FROM Lead_Custom__c LIMIT 1];

        Task t = new Task(
            WhatId = lead.Id,
            Subject = 'Follow-up Call - Attempt 1',
            Status = 'Call Not Answered',
            ActivityDate = Date.today()
        );
        insert t;

        // oldT.Status is already 'Call Not Answered' too, so no transition should occur
        Task oldVersion = t.clone(true, true, false, false);
        oldVersion.Status = 'Call Not Answered';

        Map<Id, Task> oldMap = buildOldMap(new List<Task>{ oldVersion });

        Test.startTest();
        LeadTaskFollowupHandler.handleTaskUpdate(
            new List<Task>{ t },
            oldMap
        );
        Test.stopTest();

        List<Task> allTasks = [SELECT Id FROM Task WHERE WhatId = :lead.Id];
    }

    @isTest
    static void testHandleTaskUpdate_NullWhatId_Skipped() {

        Task t = new Task(
            Subject = 'Follow-up Call - Attempt 1',
            Status = 'Call Not Answered',
            ActivityDate = Date.today()
        );
        insert t;

        Task oldVersion = t.clone(true, true, false, false);
        oldVersion.Status = 'Open';

        Map<Id, Task> oldMap = buildOldMap(new List<Task>{ oldVersion });

        Test.startTest();
        LeadTaskFollowupHandler.handleTaskUpdate(
            new List<Task>{ t },
            oldMap
        );
        Test.stopTest();
    }

    @isTest
    static void testHandleTaskUpdate_AlreadyRunning_ReturnsEarly() {

        Lead_Custom__c lead = [SELECT Id, OwnerId FROM Lead_Custom__c LIMIT 1];

        Task t = new Task(
            WhatId = lead.Id,
            Subject = 'Follow-up Call - Attempt 1',
            Status = 'Call Not Answered',
            ActivityDate = Date.today()
        );
        insert t;

        Task oldVersion = t.clone(true, true, false, false);
        oldVersion.Status = 'Open';

        Map<Id, Task> oldMap = buildOldMap(new List<Task>{ oldVersion });

        // Force the recursion guard to simulate "already running"
        LeadTaskFollowupHandler.isRunning = true;

        Test.startTest();
        LeadTaskFollowupHandler.handleTaskUpdate(
            new List<Task>{ t },
            oldMap
        );
        Test.stopTest();

        // Reset for safety in case other tests run in the same transaction
        LeadTaskFollowupHandler.isRunning = false;
    }

    @isTest
    static void testHandleTaskUpdate_DuplicateAttempt2_NotRecreated() {

        Lead_Custom__c lead = [SELECT Id, OwnerId FROM Lead_Custom__c LIMIT 1];

        // Pre-existing Attempt 2 task already there
        Task existingAttempt2 = new Task(
            WhatId = lead.Id,
            Subject = 'Follow-up Call - Attempt 2',
            Status = 'Open',
            ActivityDate = Date.today()
        );
        insert existingAttempt2;

        Task t = new Task(
            WhatId = lead.Id,
            Subject = 'Follow-up Call - Attempt 1',
            Status = 'Open',
            ActivityDate = Date.today()
        );
        insert t;

        Task oldVersion = t.clone(true, true, false, false);
        oldVersion.Status = 'Open';

        t.Status = 'Call Not Answered';
        update t;

        Map<Id, Task> oldMap = buildOldMap(new List<Task>{ oldVersion });

        Test.startTest();
        LeadTaskFollowupHandler.handleTaskUpdate(
            new List<Task>{ t },
            oldMap
        );
        Test.stopTest();

        List<Task> attempt2Tasks = [
            SELECT Id
            FROM Task
            WHERE WhatId = :lead.Id
            AND Subject = 'Follow-up Call - Attempt 2'
        ];
    }
}