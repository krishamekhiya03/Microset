public class TradeIndiaBuyLeadQueueable 
implements Queueable, Database.AllowsCallouts {

    public void execute(QueueableContext context) {

        try{
            TradeIndiaService.fetchBuyLeads();
        }
        catch(Exception e){
            System.debug('TradeIndia Buy Lead Error: ' + e.getMessage());
        }

    }
}