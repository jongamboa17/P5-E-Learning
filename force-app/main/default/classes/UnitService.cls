public class UnitService {
    @AuraEnabled(cacheable=false)
    public static boolean createUnitResponse(Id unitId,String jsonQA ) {
        system.debug(unitId);
        system.debug(jsonQA);
        Savepoint sp = Database.setSavepoint();
        Boolean verify = false;
        
        try{
            system.debug('ENTRO AL TRY');
            // busco la unidad
            Unit__c unit = [SELECT Module__c, Description__c, (SELECT Id, Tries__c FROM Unit_Responses__r WHERE Module_Response__r.User__c =: UserInfo.getUserId() ORDER BY Tries__c DESC LIMIT 1 ) FROM Unit__c WHERE Id =: unitId];
            
            //veo si existe un module response
            //primero lo busco en la bd
            Module_Response__c moduleResp;
            try{
                 moduleResp = [SELECT Id FROM Module_Response__c WHERE Module__c=: unit.Module__c AND User__c=: Userinfo.getUserId() AND Status__c = 'In Progress'];
            }catch(Exception e){
            
                //creacion de module response
                 moduleResp = new Module_Response__c(User__c = UserInfo.getUserId(), Module__c = unit.Module__c, Status__c = 'In Progress');
                 system.debug('ENTRO AL module resp');
                insert moduleResp;
            }
            
            //creacion de unit response
            Unit_Response__c unitResponse = new Unit_Response__c(Unit__c = unitId, Module_Response__c = moduleResp.Id, Status__c = 'Draft', User__c = UserInfo.getUserId());
            system.debug('ENTRO AL unit response');
            
            unitResponse.Tries__c = !unit.Unit_Responses__r.isEmpty() ? unit.Unit_Responses__r[0].Tries__c +1:1;
            insert unitResponse;
            
            //creo questions responses apartir del map que creo con el json
            Map<Id, Id> quesAnsMap = (Map<Id, Id>)JSON.deserializeStrict(jsonQA, Map<Id,Id>.class);
            List<Question_Response__c> questionResponseList = new List<Question_Response__c>();
            system.debug('QUESTIONS' + quesAnsMap);
            for (Id questId : quesAnsMap.keySet()) {
                Question_Response__c questionResponse = new Question_Response__c(Question__c = questId, Unit_Response__c = unitResponse.Id, Option__c = quesAnsMap.get(questId));
                questionResponseList.add(questionResponse);
            }
            system.debug('QUESTIONS' + questionResponseList);
            insert questionResponseList;
            
            //actualizo el unit response para disparar el proceso de evaluacion
            unitResponse.Status__c = 'Answered';
            update unitResponse;

            verify = true; 

        }catch(Exception e){
            Database.rollback(sp);
            throw e;
        }
        return verify;
        }

        //////////////////////////trail wrapper///////////////////////////////////
        //devuelve el TrailWrapper que creamos mas abajo
        
        public TrailWrapper getTrailWrapper(Id trailId){
            //Lista de módulos relacionados al Trail seleccionado:
            List<Module__c>modules = getModules(trailId);

            //Double totalUnitsCompleted = 
            //Busco trail 
            Trail__c trail = [SELECT Name, Description__c, Estimated_Time__c, Total_Points__c,Unit_Quantity__c FROM Trail__c WHERE Id =: trailId];

            //Instancio trail wrapper con trail y modules(los modules los traigo en un metodo), tambien module ids completados, unit ids completados
            TrailWrapper trailWrap = new TrailWrapper(trail, getModules(trailId), getModuleIdsCompleted(trailId), getUnitIdsCompleted(trailId));
            
            return trailWrap;
        }

        //Busco modules relacionados
        private static List<Module__c> getModules(Id trailId){

            List<Trail_Module__c> trailModules =  [SELECT Module__c FROM Trail_Module__c WHERE Trail__c =: trailId];

            Set<Id> moduleIds = new Set<Id>();
            for (Trail_Module__c trailModule : trailModules) {
                moduleIds.add(trailModule.Module__c); 
            }
             List<Module__c> modules = [SELECT Name, Description__c, Total_Points__c, Estimated_Time__c, (SELECT Name,Estimated_Time__c,Total_Points__c, Description__c FROM Units__r) FROM Module__c WHERE Id in: moduleIds];
             system.debug('UNITS :::: '+ modules);
            return modules;
        }

        private static List<Id> getModuleIdsCompleted(Id trailId){
            List<Module_Response__c> moduleResponses = [SELECT Module__c FROM Module_Response__c WHERE Status__c = 'Completed' AND Module__c IN : getModules(trailId) AND User__c =: Userinfo.getUserId()];
            Set<Id> completedModuleIds = new Set<Id>();
            for (Module_Response__c moduleResp : moduleResponses) {
                completedModuleIds.add(moduleResp.Module__c);
            }
            return new List<Id>(completedModuleIds);
            
        }
        
        private static List<Id> getUnitIdsCompleted(Id trailId){
            List<Unit_Response__c> unitResponses =[SELECT Unit__c FROM Unit_Response__c WHERE IsCorrect__c = true AND User__c =: Userinfo.getUserId() AND Unit__r.Module__c IN : getModules(trailId)];
            Set<Id> completedUnitIds = new Set<Id>();
            for (Unit_Response__c unitResp : unitResponses) {
                completedUnitIds.add(unitResp.Unit__c);
            }

            return new List<Id>(completedUnitIds);
        }



        public class TrailWrapper{
            //configuracion
            @AuraEnabled
            public Trail__c trail; //Registro de Trail solicitado
            @AuraEnabled
            public List<Module__c> modules; //Módulos con Unidades relacionadas
            
            //transaccional
            @AuraEnabled
            public List<Id> passedModuleIds; //Ids de módulos relacionados al Trail actual en los que el Alumno ya aprobó
            @AuraEnabled
            public List<Id> passedUnitIds; //Ids de Unidades relacionadas a módulos del Trail actual que el Alumno ya aprobó
            @AuraEnabled
            public Double progressTrail; //Porcentaje de progreso del Alumno en el Trail

            public TrailWrapper(Trail__c trail, List<Module__c> modules, List<Id> passedModuleIds, List<Id> passedUnitIds ){
                this.trail = trail;
                this.modules = modules;
                this.passedModuleIds = passedModuleIds;
                this.passedUnitIds = passedUnitIds;
                this.progressTrail = passedModuleIds.size() / modules.size();
                
                //system.debug(this.passedModuleIds.size());
                //system.debug(this.modules.size());
            }
        }


        public class UnitWrapper {
            //variables
            @AuraEnabled
            public Unit__c unit;
            @AuraEnabled
            public List<Question__c> questions;
            
            // constructor
            public UnitWrapper(Unit__c unit, List<Question__c> questions){
                this.unit = unit;
                this.questions = questions;
            }
        }

        //Method
        @AuraEnabled(cacheable=true)
        public static UnitWrapper getUnit(Id unitId) {
            //query to unit
            Unit__c unit = [SELECT Id, Name, Total_Points__c,  Description__c, Estimated_Time__c FROM Unit__c WHERE Id=: unitId];

            List<Question__c> listQuestions = [SELECT Id, Description__c, (SELECT Id, Name, Description__c, IsCorrect__c FROM Options__r) FROM Question__c WHERE Unit__c =: unitId];

            return new UnitWrapper(unit, listQuestions);
        }

    }