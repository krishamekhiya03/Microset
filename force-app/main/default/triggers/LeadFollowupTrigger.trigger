trigger LeadFollowupTrigger on Lead_Custom__c (after insert) {

    List<Task> taskList = new List<Task>();

    for (Lead_Custom__c leadRec : Trigger.new) {

        taskList.add(new Task(
            WhatId = leadRec.Id,
            OwnerId = leadRec.OwnerId,
            Subject = 'Follow-up Call - Attempt 1',
            Status = 'Open',
            Priority = 'Normal',
            ActivityDate = Date.today().addDays(1)
        ));
    }

    if (!taskList.isEmpty()) {
        insert taskList;
    }
}