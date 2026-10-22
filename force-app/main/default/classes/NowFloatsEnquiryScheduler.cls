public with sharing class NowFloatsEnquiryScheduler implements Schedulable {
    
    /**
     * Schedulable execute method
     */
    public void execute(SchedulableContext sc) {
        // Enqueue the Queueable job to run callout asynchronously
        System.enqueueJob(new NowFloatsEnquiryQueueable());
    }
}