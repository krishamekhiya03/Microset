global class TradeIndiaBuyLeadScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {

        System.enqueueJob(new TradeIndiaBuyLeadQueueable());

    }
}