public class TradeIndiaInquiryQueueable 
implements Queueable, Database.AllowsCallouts {

    public void execute(QueueableContext context) {

        try{
            TradeIndiaService.fetchMyInquiry();
        }
        catch(Exception e){
            System.debug('TradeIndia Inquiry Error: ' + e.getMessage());
        }

    }
}