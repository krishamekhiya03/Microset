trigger LeadTaskFollowupTrigger on Task (after update) {

    if(Trigger.isAfter && Trigger.isUpdate){

        LeadTaskFollowupHandler.handleTaskUpdate(
            Trigger.new,
            Trigger.oldMap
        );
    }
}