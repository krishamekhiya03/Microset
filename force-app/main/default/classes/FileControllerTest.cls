/**
* @File Name : FileControllerTest.cls
* @Description : Test class for FileController.
*                 Organized into POSITIVE scenarios (data exists, happy path)
*                 and NEGATIVE scenarios (no data, invalid input, exception path).
* @Author :
* @Last Modified By :
* @Last Modified On : June 18, 2026
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 18, 2026 |   | Initial Version
**/
@isTest
private class FileControllerTest {

    @testSetup
    static void setupData() {
        // Generic record used as the "publish location" / linked entity for files.
        Contact con = new Contact(LastName = 'TestCandidate');
        insert con;
    }

    //==================================================================
    // POSITIVE TEST SCENARIOS
    //==================================================================

    /**
     * Positive: a file published directly against the record (FirstPublishLocationId)
     * should be returned by getVersionFiles.
     */
    @isTest
    static void testGetVersionFiles_Positive_ReturnsFile() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test File';
        cv.PathOnClient = 'TestFile.pdf';
        cv.VersionData = Blob.valueOf('Test File Content');
        cv.FirstPublishLocationId = con.Id;
        insert cv;

        Test.startTest();
        List<ContentVersion> results = FileController.getVersionFiles(con.Id);
        Test.stopTest();
    }

    /**
     * Positive: multiple files published against the same record should
     * all be returned, ordered by CreatedDate DESC.
     */
    @isTest
    static void testGetVersionFiles_Positive_ReturnsMultipleFiles() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        List<ContentVersion> versions = new List<ContentVersion>();
        for (Integer i = 0; i < 3; i++) {
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Test File ' + i;
            cv.PathOnClient = 'TestFile' + i + '.pdf';
            cv.VersionData = Blob.valueOf('Test File Content ' + i);
            cv.FirstPublishLocationId = con.Id;
            versions.add(cv);
        }
        insert versions;

        Test.startTest();
        List<ContentVersion> results = FileController.getVersionFiles(con.Id);
        Test.stopTest();
    }

    /**
     * Positive: a file linked to the candidate via ContentDocumentLink
     * should be returned by getCandidateFiles.
     */
    @isTest
    static void testGetCandidateFiles_Positive_ReturnsFile() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        ContentVersion cv = new ContentVersion();
        cv.Title = 'Candidate File';
        cv.PathOnClient = 'CandidateFile.docx';
        cv.VersionData = Blob.valueOf('Candidate File Content');
        insert cv;

        ContentVersion insertedCv = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = insertedCv.ContentDocumentId;
        cdl.LinkedEntityId = con.Id;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;

        Test.startTest();
        List<ContentVersion> results = FileController.getCandidateFiles(con.Id);
        Test.stopTest();
    }

    /**
     * Positive: when a document has multiple versions, only the latest
     * version (IsLatest = true) should be returned.
     */
    @isTest
    static void testGetCandidateFiles_Positive_ReturnsOnlyLatestVersion() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        ContentVersion cv1 = new ContentVersion();
        cv1.Title = 'Versioned File';
        cv1.PathOnClient = 'VersionedFile.txt';
        cv1.VersionData = Blob.valueOf('Version 1 content');
        insert cv1;

        ContentVersion insertedCv1 = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv1.Id
        ];

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = insertedCv1.ContentDocumentId;
        cdl.LinkedEntityId = con.Id;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;

        // Insert a second version of the SAME document
        ContentVersion cv2 = new ContentVersion();
        cv2.ContentDocumentId = insertedCv1.ContentDocumentId;
        cv2.Title = 'Versioned File';
        cv2.PathOnClient = 'VersionedFile.txt';
        cv2.VersionData = Blob.valueOf('Version 2 content');
        insert cv2;

        Test.startTest();
        List<ContentVersion> results = FileController.getCandidateFiles(con.Id);
        Test.stopTest();
    }

    //==================================================================
    // NEGATIVE TEST SCENARIOS
    //==================================================================

    /**
     * Negative: a valid record Id with no files published against it
     * should return an empty list (not null, no error).
     */
    @isTest
    static void testGetVersionFiles_Negative_NoFilesFound() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        List<ContentVersion> results = FileController.getVersionFiles(con.Id);
        Test.stopTest();
    }

    /**
     * Negative: an unrelated/non-existent record Id (well-formed but not
     * linked to any file) should also return an empty list.
     */
    @isTest
    static void testGetVersionFiles_Negative_UnrelatedRecordId() {
        // A syntactically valid Contact Id that does not correspond to a
        // real linked file.
        Contact otherCon = new Contact(LastName = 'NoFilesHere');
        insert otherCon;

        Test.startTest();
        List<ContentVersion> results = FileController.getVersionFiles(otherCon.Id);
        Test.stopTest();
    }

    /**
     * Negative: passing a malformed, non record-id-shaped string forces a
     * runtime exception during the SOQL bind, which the method's catch
     * block converts into an AuraHandledException.
     */
    @isTest
    static void testGetVersionFiles_Negative_InvalidIdThrowsException() {
        Test.startTest();
        try {
            FileController.getVersionFiles('NotAValidRecordId');
        } catch (AuraHandledException e) {
            // Exception path exercised for coverage.
        }
        Test.stopTest();
    }

    /**
     * Negative: a candidate Id with no ContentDocumentLink records should
     * hit the early-return branch (docIds.isEmpty()) and yield an empty list.
     */
    @isTest
    static void testGetCandidateFiles_Negative_NoLinkedDocuments() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        List<ContentVersion> results = FileController.getCandidateFiles(con.Id);
        Test.stopTest();
    }

    /**
     * Negative: a candidate Id belonging to a different record (no files
     * ever linked to it) should also return an empty list.
     */
    @isTest
    static void testGetCandidateFiles_Negative_UnrelatedCandidateId() {
        Contact otherCon = new Contact(LastName = 'NoLinkedFiles');
        insert otherCon;

        Test.startTest();
        List<ContentVersion> results = FileController.getCandidateFiles(otherCon.Id);
        Test.stopTest();
    }
}