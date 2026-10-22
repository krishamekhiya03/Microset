public with sharing class PreviewFileThumbnailCardController {

    @AuraEnabled
    public static void deleteFile(
        Id contentDocumentId,
        Id recordId
    ) {

        try {

            List<ContentDocumentLink> links = [

                SELECT Id
                FROM ContentDocumentLink
                WHERE ContentDocumentId = :contentDocumentId
                AND LinkedEntityId = :recordId
            ];

            delete links;

        } catch (Exception e) {

            throw new AuraHandledException(
                e.getMessage()
            );
        }
    }
}