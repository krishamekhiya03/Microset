public class LeadTaskFollowupHandler {

    public static Boolean isRunning = false;

    public static void handleTaskUpdate(
        List<Task> newTasks,
        Map<Id, Task> oldMap
    ) {

        if(isRunning){
            return;
        }

        isRunning = true;

        String leadPrefix = Lead_Custom__c.SObjectType
            .getDescribe()
            .getKeyPrefix();

        Set<Id> leadIds = new Set<Id>();

        for(Task t : newTasks){

            Task oldT = oldMap.get(t.Id);

            if(
                t.WhatId != null &&
                String.valueOf(t.WhatId).startsWith(leadPrefix) &&
                t.Status == 'Call Not Answered' &&
                oldT.Status != 'Call Not Answered'
            ){
                leadIds.add(t.WhatId);
            }
        }

        if(leadIds.isEmpty()){
            isRunning = false;
            return;
        }

        Map<Id, Lead_Custom__c> leadMap = new Map<Id, Lead_Custom__c>(
            [SELECT Id, OwnerId, Lead_Status__c
             FROM Lead_Custom__c
             WHERE Id IN :leadIds]
        );

        // Existing tasks
        Map<Id, Set<String>> leadTaskSubjects = new Map<Id, Set<String>>();

        for(Task t : [
            SELECT Id, WhatId, Subject
            FROM Task
            WHERE WhatId IN :leadIds
        ]){

            if(!leadTaskSubjects.containsKey(t.WhatId)){
                leadTaskSubjects.put(t.WhatId, new Set<String>());
            }

            leadTaskSubjects.get(t.WhatId).add(t.Subject);
        }

        List<Task> tasksToInsert = new List<Task>();
        List<Lead_Custom__c> leadsToUpdate = new List<Lead_Custom__c>();

        for(Task t : newTasks){

            if(
                t.WhatId == null ||
                !leadIds.contains(t.WhatId)
            ){
                continue;
            }

            Lead_Custom__c lead = leadMap.get(t.WhatId);

            Set<String> existingSubjects =
                leadTaskSubjects.get(t.WhatId);

            // Attempt 1 -> Create Attempt 2
            if(
                t.Subject == 'Follow-up Call - Attempt 1' &&
                !existingSubjects.contains('Follow-up Call - Attempt 2')
            ){

                tasksToInsert.add(
                    new Task(
                        WhatId = t.WhatId,
                        OwnerId = lead.OwnerId,
                        Subject = 'Follow-up Call - Attempt 2',
                        Status = 'Open',
                        Priority = 'Normal',
                        ActivityDate = Date.today().addDays(1)
                    )
                );
            }

            // Attempt 2 -> Create Attempt 3
            else if(
                t.Subject == 'Follow-up Call - Attempt 2' &&
                !existingSubjects.contains('Follow-up Call - Attempt 3')
            ){

                tasksToInsert.add(
                    new Task(
                        WhatId = t.WhatId,
                        OwnerId = lead.OwnerId,
                        Subject = 'Follow-up Call - Attempt 3',
                        Status = 'Open',
                        Priority = 'Normal',
                        ActivityDate = Date.today().addDays(1)
                    )
                );
            }

            // Attempt 3 -> Unqualified
            else if(
                t.Subject == 'Follow-up Call - Attempt 3'
            ){

                leadsToUpdate.add(
                    new Lead_Custom__c(
                        Id = t.WhatId,
                        Lead_Status__c = 'Unqualified'
                    )
                );
            }
        }

        if(!tasksToInsert.isEmpty()){
            insert tasksToInsert;
        }

        if(!leadsToUpdate.isEmpty()){
            update leadsToUpdate;
        }

        isRunning = false;
    }
}