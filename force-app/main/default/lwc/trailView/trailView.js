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
    modulos;
    checkmodule;
    checkunit;
    get progressTrail() {
        return Math.round(this.progress);
    }

    @wire(getTrails, { trailId: '$recordId' })
    trail(Result) {
        const { data, error } = Result;
        if (data) {
            this.name = data.trail.Name;
            this.time = 'Estimated Time ' + data.trail.Estimated_Time__c + ' minutes';
            this.description = data.trail.Description__c;
            this.points = data.trail.Total_Points__c;
            this.modulos= data.modules;
            //this.passmodules = data.passedModuleIds;
            this.checkunit = data.passedUnitIds;
            this.progress = (data.passedUnitIds.length/data.trail.Unit_Quantity__c)*100;
            console.log(this.progress+ 'PROGRESSSSS');
            //this.progress = Math.round((data.passedUnitIds.length/this.modulos.length));
            //this.progress = data.progressTrail;
            this.checkmodule = data.passedModuleIds;
            
        } else if (error) {
            this.trailWrapper = undefined;
            this.error = error;
        }
    }  


   
}