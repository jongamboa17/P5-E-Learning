import { LightningElement,api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
export default class UnitView extends NavigationMixin(LightningElement) {
    @api units;

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

    ViewUnit(event) {
        console.log('entre en el boton')
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                "recordId": event.target.dataset.prop,
                "objectApiName": "Unit__c",
                "actionName": "view"
            },
        });

    }
}