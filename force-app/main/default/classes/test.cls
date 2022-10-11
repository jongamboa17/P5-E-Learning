public class test {
   public static void createUnitResponse(Id unitId ) {
        Savepoint sp = Database.setSavepoint();
        try{
            Map<Id, Id> mapExample = new Map<Id, Id>(); // Define a new map
            mapExample.put('a053t000015SvcJAAS','a083t00000XDUSOAA5');                  
            //mapExample.put('a053t000015SvcKAAS', 'a083t00000XDUSPAA5');
            // busco la unidad
            Unit__c unit = [SELECT Module__c, (SELECT Id, Tries__c FROM Unit_Responses__r WHERE Module_Response__r.User__c =: UserInfo.getUserId() ORDER BY Tries__c DESC LIMIT 1 ) FROM Unit__c WHERE Id =: unitId];
            
            //veo si existe un module response
            //primero lo busco en la bd
            Module_Response__c moduleResp;
            try{
                 moduleResp = [SELECT Id FROM Module_Response__c WHERE Module__c=: unit.Module__c AND User__c=: Userinfo.getUserId() AND Status__c = 'In Progress'];
            }catch(Exception e){
            
                //creacion de module response
                 moduleResp = new Module_Response__c(User__c = UserInfo.getUserId(), Module__c = unit.Module__c, Status__c = 'In Progress');
                insert moduleResp;
            }
            
            
            //creacion de unit response
            Unit_Response__c unitResponse = new Unit_Response__c(Unit__c = unitId, Module_Response__c = moduleResp.Id, Status__c = 'Draft');
            
            
            unitResponse.Tries__c = !unit.Unit_Responses__r.isEmpty() ? unit.Unit_Responses__r[0].Tries__c +1:1;
            insert unitResponse;
            
            
            
            //creo questions responses apartir del map que creo con el json
            //Map<Id, Id> quesAnsMap = (Map<Id, Id>)JSON.deserializeStrict(jsonQA, Map<Id,Id>.class);
            List<Question_Response__c> questionResponseList = new List<Question_Response__c>();
            
            for (Id questId : mapExample.keySet()) {
                Question_Response__c questionResponse = new Question_Response__c(Question__c = questId, Unit_Response__c = unitResponse.Id, Option__c = mapExample.get(questId));
                questionResponseList.add(questionResponse);
            }
            insert questionResponseList;
            
            //actualizo el unit response para disparar el proceso de evaluacion
            unitResponse.Status__c = 'Answered';
            update unitResponse;
        }catch(Exception e){
            Database.rollback(sp);
            throw e;
        }
        }
}