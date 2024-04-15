({

    afterRender: function (component, helper) {
        this.superAfterRender();
        if(component.get('v.firstTimeRendered')){
            var elem = component.find('InternalOpsTrainingEnableKanbanCard');
        	$A.util.addClass(elem,'newCardColor');
            window.setTimeout($A.getCallback(function() {
                    $A.util.removeClass(elem,'newCardColor');
                }), 300);
        }
    },
})