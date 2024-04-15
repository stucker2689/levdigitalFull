import { LightningElement, wire, track, api} from "lwc";

export default class DragAndDropTable extends LightningElement {
  @track dragStart;
  @api items = [];
  @track itemsCopy = [];
  @track hasRendered = true;

  renderedCallback() {
    if(this.hasRendered){
        this.itemsCopy = JSON.parse(JSON.stringify(this.items));
        this.hasRendered = false;
    }
  }

  DragStart(event) {
    try{
      this.dragStart = event.target.title;
      event.target.classList.add("drag");
    }catch(e){
      console.error('Drag Start Error: ', e);
    }
  }

  DragOver(event) {
    try{
      event.preventDefault();
      return false;
    }catch(e){
      console.error('Drag Over Error: ', e);
    }
  }

  Drop(event) {
    try{
      event.stopPropagation();
      const DragValName = this.dragStart;
      const DropValName = event.target.title;
      if (DragValName === DropValName) {
        return false;
      }
      const index = DropValName;
      const currentIndex = DragValName;
      const newIndex = DropValName;
      Array.prototype.move = function (from, to) {
        this.splice(to, 0, this.splice(from, 1)[0]);
      };
      this.itemsCopy.move(currentIndex, newIndex);

      let reIndexedItems = []
      let workNumber = 1;
      for(let item of this.itemsCopy){
        let newItem = {Id: item.Id, workName: item.workName, workIndex: workNumber};
        reIndexedItems.push(newItem);
        workNumber++;
        
      }

      this.itemsCopy = reIndexedItems;

      const orderChangedEvent = new CustomEvent("workorderchange", {
        detail: this.itemsCopy
      });

      this.dispatchEvent(orderChangedEvent);
    }catch(e){
      console.error('Drop Error: ', e);
    }
  }
}