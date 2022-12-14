import { LightningElement, wire, api,track } from 'lwc';
import { MessageContext, subcribe, publish, subscribe } from 'lightning/messageService';
import getUnit from '@salesforce/apex/UnitService.getUnit';
import createUnitResponse from '@salesforce/apex/UnitService.createUnitResponse';
import proyectoELearning from '@salesforce/messageChannel/proyectoELearning__c';
import {refreshApex} from '@salesforce/apex';
export default class UnitContent extends LightningElement {
    @api recordId;
    unit;
    questionList;
    _wireResult;
    subscription = null;
    points;
    name;
    time;
    description;
    preguntas;


    @wire(MessageContext)
    messageContext;

    /* connectedCallback() {
        if (this.subscription != null) {
            return
        }
        this.subscription = subscribe()
        this.messageContext,
            proyectoELearning,
            (message) => {
                if (message.refresh) {
                    refreshApex(this._wireResult)
                }
            }
    } */

    @wire(getUnit, { unitId: '$recordId' })
    unitdata(result) {
        const { data, error } = result;
        this._wireResult = result;

        console.log();
        if (data) {
            this.unit = data.unit;
            this.questionList = data.isCompleted ? undefined : data.QuestionList;
            this.name = this.unit.Name;
            this.points = '+' + this.unit.Total_Points__c + ' POINTS';
            this.time = 'Estimated Time ' + this.unit.Estimated_Time__c + ' minutes';
            //this.time = this.unit.Estimated_Time__c;
            this.description = this.unit.Description__c;
            this.preguntas = data.questions;
            //publish(this.messageContext, proyectoELearning, { QuestionList: this.QuestionList });

        } else if (error) {
            this.trailWrapper = undefined;
            this.error = error;
        }

    }

    @track
    optionSelected = [];
    optionSelectedjson = {};
    answerSelected(event) {

        console.log(JSON.stringify(event.detail) + 'detail event');
        this.optionSelectedjson[event.detail.questionId] = event.detail.optionId;
        console.log('objeto' + JSON.stringify(this.optionSelectedjson));
        this.optionSelected = Object.values(this.optionSelectedjson);
        console.log('arraypadre' + this.optionSelected);
    }



    handleSubmit(event) {
        createUnitResponse({
                unitId: this.recordId,
                jsonQA: JSON.stringify(this.optionSelectedjson)
            })
            .catch((error) => {
                console.log(error);
            })
         }
}