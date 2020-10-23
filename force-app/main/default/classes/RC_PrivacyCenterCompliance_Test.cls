@isTest
public class RC_PrivacyCenterCompliance_Test {

    @isTest static void test() {            
        System.debug('RC_PrivacyCenterCompliance_Test >> test > start');    	        
        RC_PCComplianceInvocable.checkMaskedComplianceFields();
        RC_PCDeleteComplianceInvocable.deleteAllComplianceReports();        
        System.debug('RC_PrivacyCenterCompliance_Test >> test > complete'); 
    }
    
}