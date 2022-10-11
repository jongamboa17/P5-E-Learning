trigger UnitResponses on Unit_Response__c (before update,after update) {
	if(Trigger.isBefore){
        UnitResponseTrigger.beforeUpdate(Trigger.new, Trigger.oldMap);
    } else {
        UnitResponseTrigger.afterUpdate(Trigger.new, Trigger.oldMap);    
    }
}