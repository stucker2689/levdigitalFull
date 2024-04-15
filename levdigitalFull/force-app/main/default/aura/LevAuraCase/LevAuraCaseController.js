({
    fetchListOfRecordTypes: function(component, event, helper) {
        helper.fetchListOfRecordTypes(component,event);
    },
    createRecord: function(component, event, helper, sObjectRecord) {

       let selectedRecordTypeId = component.get('v.recordTypePickListValue');
       if(selectedRecordTypeId != 'Campaign Services'){
        helper.createRecord(component,event);
       }else{
        helper.callAutoWorkFlow(component, event, helper);
       }
    },
    closeModal : function(component, event, helper){
       helper.closeModal(component,event);
    },
    getRecordTypePickListValue: function (component, event, helper) {
        let idx = event.target;
        if (event != null && ! $A.util.isEmpty(event) && idx != null) {
            let val = event.target.value;
            component.set('v.recordTypePickListValue', val);
        }
    },
    handleWorkFlowStatus : function (component, event, helper) {
        helper.handleAutoWorkFlowStatus(component, event, helper);
    }
})