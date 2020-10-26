public class RC_PrivacyCenterCompliance {

   @Future
    static public void checkMaskedComplianceFields() {
        
        System.debug('RC_PrivacyCenterCompliance > checkMaskedComplianceFields - start');
        
        clearLatestFlagOnLastReport();
        
        Map<String, List<FieldDefinition>> complianceEntityFieldMap = getEntityFieldMap();
        Map<String, List<RC_PrivacyField>> maskedEntityFieldMap = getMaskedEntityFieldMap();
        
        List<RC_PC_Compliance_Field__c> reportEntries = new List<RC_PC_Compliance_Field__c>();
        DateTime reportDate = System.now();
        String reportID = reportDate.format('yyyy-dd-MM hh:mm');
        
        // loop through fields with a compliance categorization and check if there is a masking policy for them		
        for (String entityName : complianceEntityFieldMap.keySet()) {
         
            System.debug('RC_PrivacyCenterCompliance > checkMaskedComplianceFields - checking compliance fields are masked for object: ' + entityName);
            List<FieldDefinition> complianceFields = complianceEntityFieldMap.get(entityName);
            
            for (FieldDefinition complianceField : complianceFields) {
                String complianceFieldName = complianceField.QualifiedApiName;
            	boolean masked = false;
                
                RC_PC_Compliance_Field__c reportEntry = new RC_PC_Compliance_Field__c(Report_ID__c = reportID,
                    																  Report_Date__c = reportDate,
                                                                                      Latest_Report__c = true,
                                                                                      Object_Name__c = entityName,
                                                                                      Field_Name__c = complianceFieldName,
                                                                                      ComplianceGroup__c = complianceField.ComplianceGroup,
                                                                                      BusinessStatus__c = complianceField.BusinessStatus,
                                                                                      SecurityClassification__c = complianceField.SecurityClassification
                                                                                     );
               
                // masked fields for this entity
                List<RC_PrivacyField> maskedFields = maskedEntityFieldMap.get(entityName);
                if (maskedFields == null) {
                    // no masked fields for this object that has compliance fields
                } else {
                    // check for matching masking policy for compliance fields
                    
                    for (RC_PrivacyField maskedField : maskedFields) {
                        //System.debug('entityName: ' + entityName + ', maskedField object: ' + maskedField.objectApiName 
                        //             + ', complianceFieldName: ' + complianceFieldName + ', maskedField: ' + maskedField.fieldApiName);
                        if ((maskedField.objectApiName == entityName) 
                            && (maskedField.fieldApiName == complianceFieldName)) {
                            masked = true;
                            reportEntry.Policy_Config__c = maskedField.policyConfigName;
                            reportEntry.Masking_Type__c = maskedField.maskingType;
                            reportEntry.Field_Type__c = maskedField.fieldType;
                            reportEntry.Masking_Category__c = maskedField.maskingCategory;
                        }
                    }
                }
                if (masked) {
                    System.debug('RC_PrivacyCenterCompliance > checkMaskedComplianceFields >> compliance field (' + complianceFieldName + ') is masked');
                } else {
                    System.debug(' RC_PrivacyCenterCompliance > checkMaskedComplianceFields >> compliance field (' + complianceFieldName + ') is NOT masked');
                }
                reportEntry.isMasked__c = masked;
                reportEntries.add(reportEntry);
            }
        
        }
        
        System.debug('RC_PrivacyCenterCompliance > checkMaskedComplianceFields - reportEntries: ' + reportEntries.size()); 
        for (RC_PC_Compliance_Field__c entry : reportEntries) {
            System.debug('RC_PrivacyCenterCompliance > checkMaskedComplianceFields - reportEntry: ' + entry);
        }
       
        // insert report entries
        insert reportEntries;
        
        System.debug('RC_PrivacyCenterCompliance > checkMaskedComplianceFields - complete');
        
    } // checkMaskedComplianceFields
    
    static public Map<String, List<RC_PrivacyField>> getMaskedEntityFieldMap() {
        
        System.debug('RC_PrivacyCenterCompliance > getMaskedEntityFieldMap - start');
                
        List<privacycenter__Data_Policy__mdt> configs = [SELECT Id, DeveloperName
                                                               //(SELECT Id, DeveloperName, MasterLabel FROM datamask__Masking_Objects__r)
                                                               FROM privacycenter__Data_Policy__mdt];
        System.debug('RC_PrivacyCenterCompliance > getMaskedEntityFieldMap - configs: (' + configs.size() + ') ' + configs);
        
        // map of <entity name, List of masked fields>
        Map<String, List<RC_PrivacyField>> entityFieldMap = new Map<String, List<RC_PrivacyField>>();
        
        for (privacycenter__Data_Policy__mdt config : configs) {
                        
            List<privacycenter__Data_Object__mdt> maskingObjects = [SELECT Id, privacycenter__API_Name__c FROM privacycenter__Data_Object__mdt WHERE privacycenter__Data_Policy__c = :config.Id];
        	System.debug('RC_PrivacyCenterCompliance > getMaskedEntityFieldMap > config: ' + config.DeveloperName + ' - masking objects: ' + maskingObjects.size());
            
            for (privacycenter__Data_Object__mdt maskingObject : maskingObjects) {
                System.debug('RC_PrivacyCenterCompliance > getMaskedEntityFieldMap >> masking object: ' + maskingObject);
                
                List<privacycenter__Data_Field__mdt> maskingFields = [SELECT Id, privacycenter__API_Name__c, privacycenter__Masking_Type__c, privacycenter__Field_Type__c, 
                                                                    privacycenter__Field_Length__c, privacycenter__Masking_Category__c
                                                                    FROM privacycenter__Data_Field__mdt WHERE privacycenter__Data_Object__c = :maskingObject.Id];
                
                // convert from datamask__Masking_Field__mdt to apex type RC_PrivacyField
                List<RC_PrivacyField> dmFields = new List<RC_PrivacyField>();
                for (privacycenter__Data_Field__mdt field : maskingFields) {
                    RC_PrivacyField dmField = new RC_PrivacyField();
                    dmField.objectApiName = maskingObject.privacycenter__API_Name__c;
                    dmField.policyConfigName = config.DeveloperName;
                    dmField.fieldApiName = field.privacycenter__API_Name__c;
                    dmField.fieldType = field.privacycenter__Field_Type__c;
                    dmField.maskingType = field.privacycenter__Masking_Type__c;
                    dmField.maskingCategory = field.privacycenter__Masking_Category__c;
                    dmFields.add(dmField);
                }
				System.debug('RC_PrivacyCenterCompliance > getMaskedEntityFieldMap - masking fields: ' + dmFields.size());                
                
                // put object and fields in map
                List<RC_PrivacyField> existing_dmFields = entityFieldMap.get(maskingObject.privacycenter__API_Name__c);
                if (existing_dmFields == null) {
                	entityFieldMap.put(maskingObject.privacycenter__API_Name__c, dmFields);
                } else {
                    // append dmFields to existing dmFields
                    dmFields.addall(existing_dmFields);
                    entityFieldMap.put(maskingObject.privacycenter__API_Name__c, dmFields);
                }
            
                for (RC_PrivacyField dmField : dmFields) {
                    System.debug('RC_PrivacyCenterCompliance > getMaskedEntityFieldMap >>> masking field: ' + dmField);
                } 
            }            
        }
        
        System.debug('RC_PrivacyCenterCompliance > getMaskedEntityFieldMap - masked entityFieldMap: ' + entityFieldMap.size());
        for (String key : entityFieldMap.keySet()) {
            System.debug('RC_PrivacyCenterCompliance > getMaskedEntityFieldMap > masked fields for object: ' + key);
            List<RC_PrivacyField> maskedFields = entityFieldMap.get(key);           
            for (RC_PrivacyField field : maskedFields) {
                System.debug('RC_PrivacyCenterCompliance > getMaskedEntityFieldMap >> ' + field);
            }
        }
        System.debug('RC_PrivacyCenterCompliance > getMaskedEntityFieldMap - complete');
                     
        return entityFieldMap;
        
    } // end getMaskedEntityFieldMap
    
    static public Map<String, List<FieldDefinition>> getEntityFieldMap() {
        
        System.debug('RC_PrivacyCenterCompliance > getEntityFieldMap - start');
        
        List<EntityDefinition> allEntities = [SELECT DurableId, DeveloperName, MasterLabel, QualifiedApiName 
                                              FROM EntityDefinition WHERE IsCustomSetting = false ORDER BY DeveloperName];
        System.debug('RC_PrivacyCenterCompliance > getEntityFieldMap - allEntities: (' + allEntities.size() + ')');
        
        // filter out meta objects
        List<String> entityNames = new List<String>();
        Map<String, EntityDefinition> entities = new Map<String, EntityDefinition>();
        for (EntityDefinition entity : allEntities) {
            if (entity.MasterLabel.startsWith('History:') 
                || entity.MasterLabel.startsWith('Change Event:') 
                || entity.MasterLabel.startsWith('Share:') 
                || entity.MasterLabel.startsWith('Feed:') 
                || entity.MasterLabel.startsWith('Tag:')){}
            else { 
                entityNames.add(entity.QualifiedApiName);
                entities.put(entity.DurableId, entity);
            }
        }
        System.debug('RC_PrivacyCenterCompliance > getEntityFieldMap - entity names: (' + entityNames.size() + ')');
        System.debug('RC_PrivacyCenterCompliance > getEntityFieldMap - filtered entities: (' + entities.size() + ')');       
        
        /*
        for (EntityDefinition entity : entities.values()) {
            Integer i = 0;
            System.debug(++i + ': ' + entity);
        }
		*/
        
        List<FieldDefinition> fieldDefinitions = [SELECT DurableId, EntityDefinitionId, DeveloperName, QualifiedApiName, 
                                                  BusinessStatus, SecurityClassification, ComplianceGroup  
                                                  FROM FieldDefinition 
                                                  WHERE EntityDefinition.QualifiedApiName IN :entityNames AND ComplianceGroup != NULL
                                                 ];
        System.debug('RC_PrivacyCenterCompliance > getEntityFieldMap - fieldDefinitions: ' + fieldDefinitions.size());
        
        // map <Entity.Id, List of FieldDefinition>
        Map<String, List<FieldDefinition>> entityFieldMap = new Map<String, List<FieldDefinition>>();        
        for (FieldDefinition field : fieldDefinitions) {
            List<FieldDefinition> entityFieldDefs = entityFieldMap.get(field.EntityDefinitionId);
            if (entityFieldDefs == null) entityFieldDefs = new List<FieldDefinition>();
            entityFieldDefs.add(field);
            entityFieldMap.put(field.EntityDefinitionId, entityFieldDefs);            
        }
        
		// update map keys from Entity.Id to Entity.QualifiedApiName
		Map<String, List<FieldDefinition>> entityFieldMap2 = new Map<String, List<FieldDefinition>>();
        for (String key : entityFieldMap.keySet()) {
            //System.debug('> key: ' + key);
            List<FieldDefinition> entityFieldDefs = entityFieldMap.get(key);
            EntityDefinition entity = entities.get(key);
            //System.debug('> qualifiedApiName: ' + entity.QualifiedApiName);
            entityFieldMap2.put(entity.QualifiedApiName, entityFieldDefs);
        }
        
        System.debug('RC_PrivacyCenterCompliance > getEntityFieldMap - entityFieldMap: ' + entityFieldMap2.size());
        for (String key : entityFieldMap2.keySet()) {
            System.debug('RC_PrivacyCenterCompliance > getEntityFieldMap > compliance fields for object: ' + key);
            List<FieldDefinition> entityFieldDefs = entityFieldMap2.get(key);           
            for (FieldDefinition field : entityFieldDefs) {
                System.debug('RC_PrivacyCenterCompliance > getEntityFieldMap >> ' + field);
            }
        }
        
        System.debug('RC_PrivacyCenterCompliance > getEntityFieldMap - complete');        
        return entityFieldMap2;
                     
    } // end getEntityFieldMap

	static public void clearLatestFlagOnLastReport() {
        System.debug('RC_PrivacyCenterCompliance > clearLatestFlagOnLastReport - start');  
        List<RC_PC_Compliance_Field__c> reportEntries = [SELECT Id FROM RC_PC_Compliance_Field__c WHERE Latest_Report__c = true];
        for (RC_PC_Compliance_Field__c entry : reportEntries) {
            entry.Latest_Report__c = false;
        }
        update reportEntries;
        System.debug('RC_PrivacyCenterCompliance > clearLatestFlagOnLastReport - complete');  
    }
    
    static public void deleteAllComplianceReports() {
        List<RC_PC_Compliance_Field__c> entries = [SELECT Id FROM RC_PC_Compliance_Field__c];
        if (entries.size() > 0) {
			delete entries;
            System.debug('RC_PrivacyCenterCompliance > deleteAllComplianceReports - deleted ' + entries.size() + ' report entries');  
    	}
    }
    
    static public void deleteComplianceReports(List<String> reportIDs) {
        System.debug('RC_PrivacyCenterCompliance > deleteComplianceReports - reportIDs: ' + reportIDs);
        List<RC_PC_Compliance_Field__c> entries = [SELECT Id FROM RC_PC_Compliance_Field__c WHERE Report_ID__c IN :reportIDs];
        if (entries.size() > 0) {
			delete entries;
            System.debug('RC_PrivacyCenterCompliance > deleteComplianceReports - deleted ' + entries.size() + ' report entries');  
    	}
    }
    
} // end RC_PrivacyCenterCompliance