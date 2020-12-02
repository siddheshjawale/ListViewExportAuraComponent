({
    getListViewsHelper : function(component, event, helper){
        var objectApiName= component.get('v.objectApiName');
        if(objectApiName != null){
            var action = component.get("c.getListViews");
            action.setParams( {ObjectName : objectApiName});
            action.setCallback(this, function(response){
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set("v.sObjectListViewList", response.getReturnValue());
                    component.set("v.showSpinner", false);
                }
            });
            $A.enqueueAction(action);
        }
    },
    
    getDataHelper : function(component, event, helper, defaultListView){
        var objectApiName= component.get('v.objectApiName');
        if(objectApiName != null){
            component.set("v.message", null);
            component.set("v.showSpinner", true);
            
            var selected = defaultListView == null ? component.find("selectedViewId").get("v.value") : defaultListView;
            if(selected == null || selected == undefined || selected == ''){
                component.set("v.showSpinner", false);
                return;
            }
            this.getsObjectDataHelper(component, event, helper, selected);
        }
    },
    
    getsObjectDataHelper : function(component, event, helper, selected) {
        var action = component.get("c.getData");
        action.setParams({ObjectName : component.get('v.objectApiName'), filterId : selected, limitRecords : component.get('v.limitRecords')});
        action.setCallback(this, function(response){
            if (response.getState() === "SUCCESS"){
                var data = response.getReturnValue();
                if(data.errorMessage != null){
                    component.set("v.Type", 'error');
                    component.set("v.message", data.errorMessage);
                    component.set("v.showSpinner", false);
                } else {
                    component.set("v.mycolumns", data.columns);
                    if(data.data.length > 0){
                        this.downloadCsv(component,event, helper, data.data);
                    } else {
                        component.set("v.Type", 'error');
                        component.set("v.message",'No Records Found');
                        component.set("v.showSpinner", false);
                    }
                }
            } else if (response.getState() === "ERROR"){
                component.set("v.Type", 'error');
                var errors = response.getError();
                if(errors){
                    component.set("v.message",'An Error Occurred. Please contact your Administrator');
                    component.set("v.showSpinner", false);
                }
            }
        });
        $A.enqueueAction(action); 
    },
    
    convertArrayOfObjectsToCSV : function(component, objectRecords){
        var csvStringResult, counter, keys, columnDivider, lineDivider;
        if (objectRecords == null || !objectRecords.length) {
            return null;
        }
        
        columnDivider = ',';
        lineDivider =  '\n';
        var getcolumn= component.get('v.mycolumns');
        var columnname= [];
        keys = [];
        var types = [];
        for(var i=0; i < getcolumn.length; i++){
            columnname.push(getcolumn[i].label);
            keys.push(getcolumn[i].fieldName);
            types.push(getcolumn[i].fieldType);
        }
        
        csvStringResult = '';
        csvStringResult += columnname.join(columnDivider);
        csvStringResult += lineDivider;
        
        for(var i=0; i < objectRecords.length; i++){   
            counter = 0;
            for(var sTempkey in keys) {
                var skey = keys[sTempkey] ;  
                if(skey.includes(".")){
                    if(counter > 0){ 
                        csvStringResult += columnDivider; 
                    }   
                    var reference = skey.split('.')[0];
                    var field = skey.split('.')[1];
                    if(objectRecords[i][reference] != null){
                        if(types[sTempkey] == 'TEXTAREA'){
                            objectRecords[i][reference][field] = objectRecords[i][reference][field].replace(/(\r\n|\n|\r)/gm,"");
                        }
                        csvStringResult += '"' + objectRecords[i][reference][field] + '"';
                    } 
                } else {
                    if(counter > 0){ 
                        csvStringResult += columnDivider; 
                    }   
                    if(objectRecords[i][skey]!= null){
                        if(types[sTempkey] == 'TEXTAREA'){
                            objectRecords[i][skey] = objectRecords[i][skey].replace(/(\r\n|\n|\r)/gm,"");
                        }
                        csvStringResult += '"' + objectRecords[i][skey] + '"';
                    } else {
                        csvStringResult += '""'; 
                    }
                }
                counter++;
            }
            csvStringResult += lineDivider;
        }
        return csvStringResult;        
    },
    
    downloadCsv : function(component, event, helper, sObjectList){            
        var csv = this.convertArrayOfObjectsToCSV(component, sObjectList);
        if (csv == null){  
            component.set("v.message",'No records in list view to export');
            component.set("v.showSpinner", false);
            return;
        } else {
            var blob = new Blob([csv]);
            if (window.navigator.msSaveOrOpenBlob) {
                navigator.msSaveBlob(blob, component.get("v.fileName"));
                component.set("v.showSpinner", false);
            } else {
                var a = window.document.createElement("a");
                a.href = window.URL.createObjectURL(blob, {type: "text/plain"});
                a.download = component.get("v.fileName");
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                
                helper.showToastMessage(component,"SUCCESS","Success","Export Successful");
                component.set("v.showSpinner", false);
                this.returnBack(component, event, helper);
            }
        }
    },
    
    returnBack : function(component, event, helper){
        component.find("selectedViewId").set("v.value", null);
        component.set("v.message", null);
        
        let workspaceAPI = component.find("workspace");
        workspaceAPI.isConsoleNavigation().then(function(isConsole) {
            if(isConsole){
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    if(response.tabId !== null){ workspaceAPI.closeTab({ tabId: response.tabId }); }
                }).catch(function(error) { console.log(error); });
            } else {
                var returnURL = component.get("v.returnURL");
                if(returnURL != null && returnURL != '' && returnURL != undefined){
                    this.navigate(returnURL);
                } else {
                    window.history.back();
                }
            }
        });
    },
})