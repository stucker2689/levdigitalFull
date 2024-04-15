({
    doInit : function(component, event, helper) {
        let allColumnRecords = component.get('v.KanbanRecords')[component.get('v.pickvalue')];
        component.set('v.recs', allColumnRecords);
        let rollupTotal = 0;

        if(allColumnRecords){
            for (let rec of allColumnRecords){
                if(rec.EstimatedHours){
                    rollupTotal += Math.round(rec.EstimatedHours);
                }
            }
        }
        component.set('v.RollupAmount', rollupTotal);
    },
    allowDrop : function(component, event, helper) {
        event.preventDefault();
    },
    drag : function (component, event, helper) {
        let co = {'from': event.currentTarget.parentElement.getAttribute('data-Pick-Val'),
                    'pos' : event.currentTarget.value}
        event.dataTransfer.setData("text", JSON.stringify(co));
    },
    drop : function (component, event, helper) {
        event.preventDefault();
        let data = JSON.parse(event.dataTransfer.getData("text"));
        data.to = event.currentTarget.getAttribute('data-Pick-Val');
        component.set('v.goingTo', event.currentTarget.getAttribute('data-Pick-Val'));
        
        let kcevt = component.getEvent('kanbanChildChanged');
        kcevt.setParams({
            "KanbanChildChange" : data
        });
        kcevt.fire();
         
        let ulEle = component.find('hckCol').getElement();
        if(!ulEle.scrollTop == 0){
            ulEle.scrollTop = 0;
        }
        
    },
    recordsChanged  : function (component, event, helper) {
        let allColumnRecords = component.get('v.KanbanRecords')[component.get('v.pickvalue')];
        component.set('v.recs', allColumnRecords);
        let rollupTotal = 0;
        if(allColumnRecords){
            for (let rec of allColumnRecords){
                if(rec.EstimatedHours){
                    rollupTotal += Math.round(rec.EstimatedHours);
                }
            }
        }
        component.set('v.RollupAmount', rollupTotal);
        //helper.countUpHelper(component);
    },
    sLoaded : function(component, event, helper){
        //helper.countUpHelper(component);
    },
    handleSortColumn : function (component, event) {
        let sprintView = component.get('v.SprintView');
        let sortFlip = component.get('v.sortFlip');
        let allColumnRecords = component.get('v.KanbanRecords')[component.get('v.pickvalue')];
        let column = component.get('v.pickvalue');
        if(sprintView){
            if(!sortFlip){
                allColumnRecords.sort(function(a, b){
                    return b.diffFromTodayToDueDate - a.diffFromTodayToDueDate
                });
                component.set('v.sortFlip', true);
                component.set('v.sortIcon', 'down');
            }else{
                allColumnRecords.sort(function(a, b){
                    return a.diffFromTodayToDueDate - b.diffFromTodayToDueDate
                });                
                component.set('v.sortFlip', false);
                component.set('v.sortIcon', 'up');
            }

        }else{
            if(!sortFlip){
                if(column == 'In Process'){
                    allColumnRecords.sort(function(a, b){
                        return new Date(b.diffFromTodayToDueDate) - new Date(a.diffFromTodayToDueDate)
                    });
                }else{
                    allColumnRecords.sort(function(a, b){
                        return new Date(b.SubmittedDate) - new Date(a.SubmittedDate)
                    });
                }
                component.set('v.sortFlip', true);
                component.set('v.sortIcon', 'down');
            }else{
                if(column == 'In Process'){
                    allColumnRecords.sort(function(a, b){
                        return new Date(a.diffFromTodayToDueDate) - new Date(b.diffFromTodayToDueDate)
                    });
                }else{
                    allColumnRecords.sort(function(a, b){
                        return new Date(a.SubmittedDate) - new Date(b.SubmittedDate)
                    });
                }                
                component.set('v.sortFlip', false);
                component.set('v.sortIcon', 'up');
            }
        }

        component.set('v.recs', allColumnRecords);
        
    }
})