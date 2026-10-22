public class IndiaMartQueueable 
implements Queueable, Database.AllowsCallouts {

    public void execute(QueueableContext context) {
        IndiaMartService.fetchLeads();
    }
}