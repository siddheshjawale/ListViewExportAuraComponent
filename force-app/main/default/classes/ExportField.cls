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
public class ExportField {
	@AuraEnabled public String fieldName;
    @AuraEnabled public String fieldType;
    @AuraEnabled public String label;
    
    public ExportField(){}
    
    public ExportField(String fieldName, String fieldType, String label){
        this.fieldName = fieldName;
        this.fieldType = fieldType;
        this.label = label;
    }
}