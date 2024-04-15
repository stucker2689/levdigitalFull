({
    countUpHelper : function(component) {
        //let KanbanRollup = component.set('v.RollupAmount');
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
        let KanbanRollup = rollupTotal ? rollupTotal : 0;
        let psumval = component.get('v.psumval');
        if(KanbanRollup){
            let options = {
                useEasing : true, 
                useGrouping : true, 
                separator : ',', 
                decimal : '.', 
            };
            let deci = 0;
            if(KanbanRollup){
                let demo = new CountUp(component.find('cup').getElement(), psumval, KanbanRollup, deci, 1, options);
                demo.start();
                component.set('v.psumval',KanbanRollup);
            }
            else{
                let demo = new CountUp(component.find('cup').getElement(), psumval, 0, deci, 1, options);
                demo.start();
                component.set('v.psumval', 0);
            }
        }
    }
})