/* eslint-disable no-console */
import { LightningElement, api } from 'lwc';
import Skill_Focus from '@salesforce/label/c.Skill_Focus';

export default class SkillsMatrixContactTable extends LightningElement {
  @api rowData;
  currentSelection;
  areaFocus;
  label = {Skill_Focus};

  get ratingOptions() {
    console.log('hit get rating option');
    return [
      { label: '0', value: '0' },
      { label: '1', value: '1' },
      { label: '2', value: '2' },
      { label: '3', value: '3' },
    ]
  }

  handleFocus(event){
    event.preventDefault();
    const focusEvent = new CustomEvent('focus', {
      detail: {focusArea: event.target.checked, skillId: event.target.name}
    });

    //Fire Event
    this.dispatchEvent(focusEvent);
  }

  handleChange(event) {
    const selectedOption = event.detail.value;
      console.log(`Option selected with value: ${selectedOption}`);
    event.preventDefault();
    //Create CustomEvent
    const ratingEvent = new CustomEvent('rating', {
      detail: {value: event.target.value, skillId: event.target.name, focusArea: event.target.focusArea}
    });

    //Fire Event
    this.dispatchEvent(ratingEvent); 
  }

  @api
  setSelectRow(highlightStyle, changedRow, skillMap) {
   var changedVal = this.rowData.find(function(skill){
      return skill.skillId === changedRow.skillId;
    });
    console.log('changedVal ' + JSON.stringify(changedVal));
    console.log('skillMap ' + JSON.stringify(skillMap));
    console.log('changedRow ' + JSON.stringify(changedRow));

    //updated to clone object because of "proxy: trap returned falsish for property" error, due shadow dom?
    this.rowData.forEach(row =>{
      let updatedRow =JSON.parse(JSON.stringify(row));
      if(row.skillId === changedRow.skillId) {
        updatedRow.selectRow = highlightStyle;
        updatedRow.rating = changedRow.value;
        updatedRow.focusArea = changedRow.focusArea;
        row = updatedRow;
        console.log('row' + JSON.stringify(row));
      }
      
    });
  }

  @api
  handleCancel(event) {
   /* this.rowData.forEach(row => {
      var index = data.findIndex(function(rowIndex){
        return rowIndex.Skill__c === row.skillId
      });
      if(index >= 0) {
      // eslint-disable-next-line vars-on-top
      var dataRating = data[index].Rating__c;
      if(row.rating !== dataRating) {
        this.rowData[index].rating = row.rating;
      }
    }
    });
  }*/
   //refreshApex(this.rowData);
  }
}