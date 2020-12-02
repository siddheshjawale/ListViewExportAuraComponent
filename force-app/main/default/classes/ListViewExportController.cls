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
//Test Class - GenericStandardListViewExportCon_Test
public class ListViewExportController {
    
    @AuraEnabled
    public static ListViewExport getData(String ObjectName, String filterId, Integer limitRecords){
        ListViewExport dataCon = new ListViewExport();
        getFilteredsObjectData(dataCon, filterId, ObjectName, limitRecords);
        generateColumns(dataCon, ObjectName);
        processData(dataCon, ObjectName);
        return dataCon;
    }
    
    @AuraEnabled
    public static List<ListView> getListViews(String ObjectName){
        List<ListView> listviews = new List<ListView>();
        for(ListView lstObj : [SELECT Id, Name FROM ListView WHERE SobjectType =: ObjectName AND IsSoqlCompatible = true order by name ASC]){
            listviews.add(lstObj);
        }
        return listviews; 
    }
    
    @TestVisible
    private static void processData(ListViewExport dataCon, String ObjectName){
        if(dataCon.errorMessage == null && !dataCon.data.isEmpty()){
            List<ExportField> columns = dataCon.columns;
            for(ExportField field : dataCon.columns){
                if(field.fieldType == 'TEXTAREA'){
                    for(sObject dat : dataCon.data){
                        if(dat.get(field.fieldName) != null){
                            dat.put(field.fieldName, String.valueOf(dat.get(field.fieldName)).replace(',',' '));
                        }
                    }
                }
            }
        }
    }
    
    @TestVisible
    private static void generateColumns(ListViewExport dataCon, String ObjectName){
        if(dataCon.errorMessage == null){
            List<String> fieldsList = dataCon.query.substringAfter('SELECT').substringBefore('FROM').split(',');
            Map<String, SObjectField> fields = Schema.getGlobalDescribe().get(ObjectName).getDescribe().fields.getMap();
            Schema.DescribeFieldResult sc;
            List<String> systemFields = Label.SystemFields.split(',');
            List<String> addedFields = new List<String>();
            Map<String, String> fieldMapping = getMapping(ObjectName);
            for(String f : fieldsList){
                String actualField = refineField(f);
                String refinedField = refineField2(actualField);
                if(!systemFields.contains(refinedField)){
                    if(fields.containsKey(refinedField)){
                        System.debug('if '+actualField);
                        sc = fields.get(refinedField).getDescribe();
                        if(!addedFields.contains(sc.getLabel())){
                            addedFields.add(sc.getLabel());
                            dataCon.columns.add(new ExportField(actualField, String.valueOf(sc.getType()), sc.getLabel()));
                        }
                    } else {
                        if(fieldMapping.containsKey(actualField)){
                            addedFields.add(sc.getLabel());
                            dataCon.columns.add(new ExportField(actualField, 'REFERENCE', fieldMapping.get(actualField)));
                        }
                        System.debug('else '+actualField);
                    }
                }
            }
        }
    }
    
    @RemoteAction @ReadOnly
    public static void getFilteredsObjectData(ListViewExport dataCon, String filterId, String ObjectName, Integer limitRecords){
        HttpRequest req = new HttpRequest();
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        String createUrl = '/services/data/v46.0/sobjects/'+ObjectName ;
        String endPoinURL = baseUrl+createUrl +'/listviews/'+filterId+'/describe';
        req.setEndpoint(endPoinURL);
        req.setMethod('GET');
        req.setHeader('Authorization',  'Bearer ' + getToken());
        
        if(Test.isRunningTest()){
            ExportCalloutMock queryMock = new ExportCalloutMock(ExportCalloutMock.CalloutType.QUERY);
            Test.setMock(HttpCalloutMock.class, queryMock);
        }
        
        Http http = new Http();
        HTTPResponse response = http.send(req);
        Map<String, Object> tokenResponse = new Map<String, Object>();
        try{
            if(response.getBody()!=''){
                tokenResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            }
        } catch(Exception e){
            List<Object> tokenResponseList = (List<Object>) JSON.deserializeUntyped(response.getBody());
            for(Object o : tokenResponseList){
                Map<String, Object> oMap = (Map<String, Object>) o;
                if(oMap.containsKey('message') && String.valueOf(oMap.get('message')) == 'List view not found.'){
                    dataCon.errorMessage = 'You cannot export private List Views';
                    return;
                }
            }
        }
        
        String query = tokenResponse.containsKey('query')?(String) tokenResponse.get('query'):'';
        system.debug('query--'+query);
        List<sObject> AccountList = new List<sObject>();
        try {
            if(query!=''){
                query += ' limit ' + String.valueOf(limitRecords);
                dataCon.query = query;
                dataCon.data = database.query(query);
            }            
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('ID not available.'));
            return;
        }  
    }
    
    public static String getToken(){
        Export__mdt loginUserSetting = [select Client_Id__c, Client_Secret__c, Username__c, Password__c,Token__c from Export__mdt limit 1];
        If(loginUserSetting !=null){
            if(Test.isRunningTest()){
                ExportCalloutMock authMock = new ExportCalloutMock(ExportCalloutMock.CalloutType.AUTH);
                Test.setMock(HttpCalloutMock.class, authMock);
            }
            String clientId = decryptKey(loginUserSetting.Client_Id__c);
            String clientSecret = decryptKey(loginUserSetting.Client_Secret__c);
            String password = decryptKey(loginUserSetting.Password__c);
            String token = decryptKey(loginUserSetting.Token__c);
            Organization orgInfo = [Select Id, Name, isSandbox From Organization LIMIT 1];
            String endPoint;
            if(orgInfo.isSandbox){
                endPoint = 'https://test.salesforce.com/services/oauth2/token';
            } else {
                endPoint = 'https://login.salesforce.com/services/oauth2/token';
            }
            String requestBody = 'grant_type=password&client_id='+clientId+'&client_secret='+clientSecret +'&username='+loginUserSetting.userName__c+'&password='+password+token;                    
            HttpRequest httpReq = new HttpRequest();
            httpReq.SetEndPoint(endPoint);
            httpReq.SetHeader('Content-Type','application/x-www-form-urlencoded');
            httpReq.setMethod('POST');
            httpReq.setBody(requestBody);
            HttpResponse httpRes = new http().send(httpReq);
            IF(httpRes.getStatusCode() == 200){
                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(httpRes.getBody());
                return (String)responseMap.get('access_token');
            }
        }
        return null;
    }
    
    @TestVisible
    private static String refineField(String field){
        field = field.trim();
        if(field.contains('(')){
            field = field.substringAfter('(').substringBefore(')');
        }
        return field;
    }
    
    @TestVisible
    private static String refineField2(String field){
        if(field.contains('__r')){
            field = field.substringBefore('.').replace('__r', '__c');
        }
        return field;
    }
    
    @TestVisible
    private static String decryptKey(String key){
        return key == null ? null : Crypto.decrypt('AES192', EncodingUtil.base64Decode(Label.ExternalToken), Blob.valueOf('StListViewExport'), EncodingUtil.base64Decode(key)).toString();
    }
    
    public static String encryptKey(String key){
        return key == null ? null : EncodingUtil.base64Encode(Crypto.encrypt('AES192', EncodingUtil.base64Decode(Label.ExternalToken), Blob.valueOf('StListViewExport'), Blob.valueOf(key)));
    }
    
    @TestVisible
    private static Map<String, String> getMapping(String ObjectName){
        Map<String, String> fieldNameMappingMap = new Map<String, String>();
        List<ObjectAndFields__mdt> mappings = [select Field__c, Label__c from ObjectAndFields__mdt where ObjectAPIName__c =: ObjectName AND Type__c = 'Mapping'];
        for(ObjectAndFields__mdt mapp : mappings){
            fieldNameMappingMap.put(mapp.Field__c, mapp.Label__c);
        }
        return fieldNameMappingMap;
    }
}