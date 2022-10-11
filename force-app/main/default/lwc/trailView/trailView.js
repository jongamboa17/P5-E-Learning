import { LightningElement,api, wire } from 'lwc';
import getTrails from '@salesforce/apex/TrailViewController.getTrail';

export default class TrailView extends LightningElement {
    /*@api recordId;
    Name;
    Description;
    Points;
    TimeEstimate;
    trails
    @wire(getTrails, {trailId : '$recordId'})
    loadTrail({error, data}){
        if (data) {
            this.Name = data.loadTrail.Name;
            this.Description = data.loadTrail.Description__c;
            this.Points = data.loadTrail.Total_Points__c;
            this.TimeEstimate = Estimated_Time__c;
            this.error = undefined;
        } else if (error) {
            this.error = error;
        }
    }*/
    @api recordId;
    name;
    time;
    description;
    points;
    progress;
    error = undefined;
    modules;
    checkmodule;
    checkunit;
    trailCompleted=false;
    passmodules;

    @wire(getTrails, { trailId: '$recordId' })
    trail(Result) {
        const { data, error } = Result;
        if (data) {
            this.name = data.trail.Name;
            this.time = 'Estimated Time ' + data.trail.Estimated_Time__c + ' minutes';
            this.description = data.trail.Description__c;
            this.points = '+' + data.trail.Total_Points__c + ' POINTS';
            this.progress = data.progressTrail;
            this.modules= data.modules;
            this.passmodules = data.passedModuleIds;
            
            //this.checkmodule= data.
            //console.log('UNITSSSSS: ' + data.modules[0].Units__r[0]);
            //console.log(data.modules.unidades.Name + 'HOLA');
            console.log('PROGRESS: '+ this.progress);
            

        } else if (error) {
            this.trailWrapper = undefined;
            this.error = error;
        }
    }   

    //Accordion
    handleSectionToggle(event) {
        const openSections = event.detail.openSections;

        if (openSections.length === 0) {
            this.activeSectionsMessage = 'All sections are closed';
        } else {
            this.activeSectionsMessage =
                'Open sections: ' + openSections.join(', ');
        }
    }
}