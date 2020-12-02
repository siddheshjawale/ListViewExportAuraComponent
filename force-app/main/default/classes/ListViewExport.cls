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
public class ListViewExport {
	@AuraEnabled public List<sObject> data;
    @AuraEnabled public String query;
    @AuraEnabled public List<ExportField> columns;
    @AuraEnabled public String errorMessage;
    
    public ListViewExport(){
        this.columns = new List<ExportField>();
    }
}