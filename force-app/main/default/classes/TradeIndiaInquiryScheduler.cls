global class TradeIndiaInquiryScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {

        System.enqueueJob(new TradeIndiaInquiryQueueable());

    }
}