public class NowFloatsQueueable
implements Queueable, Database.AllowsCallouts {
    public void execute(QueueableContext context) {
        NowFloatsService.fetchLeads();
    }
}