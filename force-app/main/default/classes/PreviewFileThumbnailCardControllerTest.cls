@isTest
private class PreviewFileThumbnailCardControllerTest {

    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;

        ContentVersion insertedVersion = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :contentVersion.Id
        ];

        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = insertedVersion.ContentDocumentId,
            LinkedEntityId = testAccount.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert contentDocumentLink;
    }

    @isTest
    static void testDeleteFileSuccess() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        ContentDocumentLink cdl = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :testAccount.Id
            LIMIT 1
        ];

        Test.startTest();
        PreviewFileThumbnailCardController.deleteFile(
            cdl.ContentDocumentId,
            testAccount.Id
        );
        Test.stopTest();
    }

    @isTest
    static void testDeleteFileWithNoLinks() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        ContentDocumentLink cdl = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :testAccount.Id
            LIMIT 1
        ];

        Id contentDocumentId = cdl.ContentDocumentId;
        delete cdl;

        Test.startTest();
        PreviewFileThumbnailCardController.deleteFile(
            contentDocumentId,
            testAccount.Id
        );
        Test.stopTest();
    }

    @isTest
    static void testDeleteFileWithInvalidRecordId() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        ContentDocumentLink cdl = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :testAccount.Id
            LIMIT 1
        ];

        Id fakeRecordId = '001000000000001AAA';

        Test.startTest();
        PreviewFileThumbnailCardController.deleteFile(
            cdl.ContentDocumentId,
            fakeRecordId
        );
        Test.stopTest();
    }

    @isTest
    static void testDeleteFileCatchBlock() {
        Test.startTest();
        try {
            // Passing null forces a System.NullPointerException
            // which triggers the catch block and AuraHandledException
            PreviewFileThumbnailCardController.deleteFile(
                null,
                null
            );
        } catch (AuraHandledException e) {
            // Catch block in controller is now covered
        }
        Test.stopTest();
    }
}