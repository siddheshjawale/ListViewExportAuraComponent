({
    doInit : function(component, event, helper){
        helper.getListViewsHelper(component, event, helper);
    },
    
    getDataCon : function (component, event, helper) {
        helper.getDataHelper(component, event, helper, null);
    },
    
    closeExport : function (component, event, helper) {
		helper.returnBack(component, event, helper);    
    },
})