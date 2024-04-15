/**
 * Created by jmahapatra on 2/26/18.
 */
({
    doInit:function(component,event)
    {
         var ctrlAction = component.get('c.getUrls');
         ctrlAction.setCallback(this, function (actionResult) {
            if (actionResult.getState() === 'SUCCESS') {
                var response = actionResult.getReturnValue(); //console.log(response);
                component.set('v.urls',response );
            }
        });
        $A.enqueueAction(ctrlAction);
    }
})