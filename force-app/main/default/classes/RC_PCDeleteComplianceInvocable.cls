public class RC_PCDeleteComplianceInvocable {

    @InvocableMethod(label='Clear Privacy Center Compliance Fields' description='')
    static public void deleteAllComplianceReports() {
        RC_PrivacyCenterCompliance.deleteAllComplianceReports();
    }
    
}