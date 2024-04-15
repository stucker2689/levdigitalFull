({
    fetchListOfRecordTypes: function(component, event, helper) {
        helper.fetchListOfRecordTypes(component,event);
    },
    createRecord: function(component, event, helper, sObjectRecord) {
        helper.createRecord(component,event);
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
})