global class NowFloatsScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        System.enqueueJob(new NowFloatsQueueable());
    }
}