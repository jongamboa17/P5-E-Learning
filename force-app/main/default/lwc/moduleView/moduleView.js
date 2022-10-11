import { LightningElement,api } from 'lwc';

export default class ModuleView extends LightningElement {

    @api name;
    @api time;
    @api description;
    @api points;
    @api modules;
    trailCompleted = true;

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