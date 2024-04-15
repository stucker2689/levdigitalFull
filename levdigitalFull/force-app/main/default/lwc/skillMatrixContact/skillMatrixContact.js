/* eslint-disable no-unused-vars */
/* eslint-disable guard-for-in */
/* eslint-disable vars-on-top */
/* eslint-disable no-useless-concat */
/* eslint-disable no-console */
import { LightningElement, track, api, wire } from 'lwc';
import getSkillsMatrixRowsByContact from '@salesforce/apex/SkillsMatrixController.getSkillsMatrixRowsByContact';
import saveRows from '@salesforce/apex/SkillsMatrixController.saveRows';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class SkillMatrixContact extends LightningElement {
  @api recordId;
  @track loaded = false;
  @track data;
  @api copyData;
  @track error;
  @track newSkill;
  @api skillMap=[];
  @api savedSkills = [];
  @track buttonDisabled;
  @track rowData;
  @wire(getSkillsMatrixRowsByContact, { contactId: '$recordId' })
  matrixRows(result) {
    if (result.data) {
      this.setMatrixRows(result.data);
    } 
    else if (result.error) {
      this.data = undefined;
      this.error = result.error;
      this.loaded = true;
    }
    this.buttonDisabled = true;
    this.copyData = this.data;
  }

  //Handle data coming from Child rows and add them to map
  handleChange(event) {
    var foundIndex = this.skillMap.findIndex(function(skillRow) {
      return skillRow.Skill__c === event.detail.skillId;
    }); 
    
    // Skill rating
    var previousValue = this.savedSkills.findIndex(function(skillRow) {
      return skillRow.Skill__c === event.detail.skillId;
    }); 
    
    // Focus Area checkbox
    var areaFocus = this.savedSkills[previousValue].Area_of_Focus__c;
    if (event.detail.focusArea != undefined) {
      areaFocus = event.detail.focusArea;
    }
    
    //Check to see if changed value is in Map
    if (foundIndex >= 0) {
      var skillMapCopy = [...this.skillMap];
      if (event.detail.value === undefined) {
        skillMapCopy[foundIndex] = {...skillMapCopy[foundIndex], Area_of_Focus__c: areaFocus};
      } 
      else if (event.detail.focusArea === undefined) {
        skillMapCopy[foundIndex] = {...skillMapCopy[foundIndex], Rating__c: event.detail.value};
      }
      this.skillMap = skillMapCopy;
    } 
    else {
      var map = [];
      map.push({Rating__c: event.detail.value, Skill__c: event.detail.skillId, Area_of_Focus__c: areaFocus});
      this.skillMap = this.skillMap.concat(map);
    }

    //Disable buttons based on if Value has changed
    if(this.skillMap.length === 0) {
      this.buttonDisabled = true;
    } else {
      this.buttonDisabled = false;
    }

    //Send event to child component to indicate row has changed
    // console.log('skillMap ' + JSON.stringify(this.skillMap));
  }

  /* Handle Save when clicked
   * Create new Skill Rating records or update existing one
   * Display Toast whether success or failure of save
   */
  handleSave() {
    var skillsMap = JSON.stringify(this.skillMap);
    var savedSkills = JSON.stringify(this.savedSkills);
    
    saveRows({skillsMap: skillsMap, existingSkills: savedSkills, resourceId: this.recordId}).then(result => {
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Success',
          message: 'Skills saved!', 
          variant: 'success',
        }),
      );  

      // Clear temporary skills and refresh saved skills to include newly saved changes
      this.skillMap = [];
      this.setMatrixRows(result);
      
      this.buttonDisabled = true;
      this.copyData = this.data;
    }).catch(error => {
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error during save.', 
          message: error.body.message,
          variant: 'error',
        }),
      );
    });
  }
 
  //Handle Cancel and revert back changes
  handleCancel() {
    document.location.reload(true);
  }

  // Set matrix row data
  setMatrixRows(result) {
    this.savedSkills = [];
    if (result) {
      let resultData = [...result];
      this.data = resultData.map(data => {
        let dataCopy = { ...data };
        dataCopy.rows = dataCopy.rows
          .map(row => {
            return { ...row }
          })
          .sort((a, b) => {
            let sortOrder = 0;
            if (a.skillProductArea > b.skillProductArea) {
              sortOrder = 1;
            } else if (a.skillProductArea < b.skillProductArea) {
              sortOrder = -1;
            } else if (a.skillName > b.skillName) {
              sortOrder = 1;
            } else if (a.skillName < b.skillName) {
              sortOrder = -1;
            }
            return sortOrder;
          });
        dataCopy.rows.forEach(row => {
          row.rating = row.skillRating;
          row.focusArea = row.areaFocus;
          row.selectRow = false;
          this.savedSkills = this.savedSkills.concat({Rating__c:row.rating, Skill__c:row.skillId, id:row.ratingId, Area_of_Focus__c: row.focusArea});
        });
       
        return dataCopy;
      });
      this.error = undefined;
      this.loaded = true;
    } 
  }
}