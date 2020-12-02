/**
 * @description       : 
 * @author            : Siddhesh Jawale
 * @group             : 
 * @last modified on  : 12-02-2020
 * @last modified by  : Siddhesh Jawale
 * Modifications Log 
 * Ver   Date         Author            Modification
 * 1.0   12-02-2020   Siddhesh Jawale   Initial Version
**/
@isTest
global class ExportCalloutMock implements HttpCalloutMock{
public enum CalloutType {AUTH, QUERY}

    String responseBody;
    Integer statusCode;
    
    public ExportCalloutMock(CalloutType MockType){
        switch on MockType {
            when AUTH {	
                this.responsebody = '{"access_token":"SESSION_ID_REMOVED","instance_url":"https://nbcusales--Sandbox1.cs20.my.salesforce.com","id":"https://test.salesforce.com/id/00Dm00000003Vo2EAE/005m00000055i0LAAQ","token_type":"Bearer","issued_at":"1575957960211","signature":"Mw96ZDHuRBLLl/xFco53xEHdXV4+hejnTFXMIbEFjHg="}';
                this.statusCode = 200;
            }	
            when QUERY {
                this.responsebody = '{"query":"SELECT Name, RecordType.Name, Industry_Name__c, Phone, BillingState, Id, RecordTypeId, CurrencyIsoCode, CreatedDate, LastModifiedDate, SystemModstamp FROM Account WHERE RecordType.Name = \'Agency\' OR RecordType.Name = \'Client\' ORDER BY Name ASC NULLS FIRST, Id ASC NULLS FIRST"}';
                this.statusCode = 200;
            }
        }
    }
    
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(responsebody);
        res.setStatusCode(statusCode);
        return res;
    }
}