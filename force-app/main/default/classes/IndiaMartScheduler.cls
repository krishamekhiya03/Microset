global class IndiaMartScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        System.enqueueJob(new IndiaMartQueueable());
    }
}