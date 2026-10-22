/**
* @File Name : FileController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 25, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 25, 2025 |   | Initial Version
**/

public with sharing class FileController{
@AuraEnabled(cacheable=true)
    public static List<ContentVersion> getVersionFiles(String recordId){
        try {
            return [
		SELECT
		Id,
                Title,
                ContentDocumentId,
                FileType, 
		ContentSize,
		FileExtension,
		VersionNumber,
		CreatedDate,
		VersionData,
                FirstPublishLocationId
		FROM ContentVersion
		WHERE FirstPublishLocationId =:recordId
			ORDER BY CreatedDate DESC
		];
        
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

     @AuraEnabled(cacheable=true)
    public static List<ContentVersion> getCandidateFiles(Id candidateId) {
        // First, find all ContentDocumentIds linked to the candidate
        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink link : [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :candidateId
        ]) {
            docIds.add(link.ContentDocumentId);
        }
        if (docIds.isEmpty()) {
            return new List<ContentVersion>();
        }
        // Then query ContentVersion for those docs, only latest versions
        return [
            SELECT
                Id,
                Title,
                ContentDocumentId,
                FileType,
                ContentSize,
                FileExtension,
                VersionNumber,
                CreatedDate,
                VersionData,
                FirstPublishLocationId
            FROM ContentVersion
            WHERE ContentDocumentId IN :docIds
              AND IsLatest = true
            ORDER BY CreatedDate DESC
        ];
    }
}