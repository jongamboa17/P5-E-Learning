public class UnitResponseTrigger {
    public static void beforeUpdate(List<Unit_Response__c> unitRespList, Map<Id, Unit_Response__c> oldUnitRespMap  ) {
        List<Unit_Response__c> answeredUnitRespList = new List<Unit_Response__c>();
        for (Unit_Response__c unitResp : unitRespList) {
            if(unitResp.Status__c == 'Answered' && oldUnitRespMap.get(unitResp.Id).Status__c=='Draft'){
                answeredUnitRespList.add(unitResp);
            }
        }
        validateAnswers(answeredUnitRespList);
    }
    
    //pasa lista de unit response correctas a updateUserPoints para ver las unidades con las que voy a agregar los puntos a cada usuario
    public static void afterUpdate(List<Unit_Response__c> unitRespList, Map<Id, Unit_Response__c> oldUnitRespMap  ) {
        List<Unit_Response__c> correctUnitList = new List<Unit_Response__c>();
        for (Unit_Response__c unitResp : unitRespList) {
            if(unitResp.IsCorrect__c && !oldUnitRespMap.get(unitResp.Id).IsCorrect__c){
                correctUnitList.add(unitResp);
            }
        }
        updateUserPoints(correctUnitList);
    }

    private static void validateAnswers(List<Unit_Response__c> unitRespList ) {
        Map<Id, Unit_Response__c> unitRespFromDbMap = new Map<Id, Unit_Response__c>([SELECT Id,Unit__r.Total_Points__c, (SELECT Id, Option__r.IsCorrect__c FROM Question_Responses__r)FROM Unit_Response__c WHERE Id in: unitRespList]);

        for(Unit_Response__c unitResp : unitRespList){
            unitResp.IsCorrect__c = true;
            for(Question_Response__c questionResp : unitRespFromDbMap.get(unitResp.Id).Question_Responses__r) {
                if (!questionResp.Option__r.IsCorrect__c) {
                    unitResp.IsCorrect__c = false;
                    break;
                }
                
            }
			
            //asignacion puntos
            //pendiente calculo de tries en unit service
            if(unitResp.IsCorrect__c) {
                if (unitResp.Tries__c ==1) {
                    unitResp.Points__c = unitRespFromDbMap.get(unitResp.Id).Unit__r.Total_Points__c;
                } else if(unitResp.Tries__c == 2){
                    unitResp.Points__c = unitRespFromDbMap.get(unitResp.Id).Unit__r.Total_Points__c/2;
                } else {
                    unitResp.Points__c = unitRespFromDbMap.get(unitResp.Id).Unit__r.Total_Points__c/4;
                }
            }
        }
    }

    //metodo para actualizar los puntos de usuario
    //voy a llegar al usuario por medio de un lookup para hacerlo mas facil
    private static void updateUserPoints(List<Unit_Response__c> unitRespList ) {

        //guardo los ids de los usuarios relacionados a la unit response
        Set<Id> usersIds = new Set<Id>();
        for (Unit_Response__c unitResp : unitRespList) {
            usersIds.add(unitResp.userId__c);
        }
       
        //busco los usuarios filtrados por el set userIds
        Map<Id,User> usersMap = new Map<Id,User>([SELECT Id, Total_Points__c FROM User WHERE Id in : usersIds]);
		
       
        //actualizo en memoria los pts del user en base al unit response
        // ese user hace referencia al del map y al cambiarlo cambia el del map
        //cuando le cambio por referencia-> user.Total_Points__c, se cambia en el map automaticamente
        for (Unit_Response__c unitResp : unitRespList) {
            //usersMap.get(unitResp.userId__c).Total_Points__c += unitResp.Points__c;
            
            User usuario = usersMap.get(unitResp.userId__c);
            System.debug('USER'+usuario);
            System.debug('USER'+usuario.Total_Points__c);
            System.debug('unit points'+unitResp.Points__c);
            //usuario.Total_Points__c == null ? usuario.Total_Points__c = unitResp.Points__c : usuario.Total_Points__c += unitResp.Points__c;
            if(usuario.Total_Points__c == null) {
                usuario.Total_Points__c = unitResp.Points__c;
            } else {
                usuario.Total_Points__c += unitResp.Points__c;
            }
        }
        //no le puedo pasar el map porque no se puede hacer update de un map, entonces uso .values() que me pasa una lista con los valores del map
        update usersMap.values();
    }
}