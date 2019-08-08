trigger CaseAssignmentBefore on Case (before insert, before delete, before update) {
/**
* Author: Peter Sewell
* TEST ONLY - FOR COMPLAINT CASE ASSIGNMENT 
*
* This trigger is responsible for keeping the Case_Assignment__c field on the case record in sync with the corresponding CA record of the case owner
* Essentially the Case_Assignment__c field should always point to the Case_Assignment record of the user who owns the Case
* The Case_Assignment__c field will however be set to null if: 1.case owner is a user without a Case_Assignment record OR 2. case owner is a queue
**/
   	String statusChangeType = '';  	// the type of staus change
    String ownerChangeType = '';   	// the type of ownership change
    String oldOwner = '';
    String newOwner = '';   
    
   	System.debug('--*Entering Case Assignment Trigger - Before*--');

    if(Trigger.isInsert){
        for (Case newCase: Trigger.new) {
            newOwner = newCase.OwnerId;
            switch on newOwner.left(3) {
                when '005' {
                    // Set Case_Assignment field on case if the Case Owner for this case has a Case_Assignment record
                    ownerChangeType = 'N2U';
                    List<Case_Assignment__c> ca = [SELECT Id FROM Case_Assignment__c WHERE User__c = :newOwner limit 1 ];
                    if(ca != null && ca.size()>0){
                        newCase.Case_Assignment__c = ca[0].Id;
                    } 
                }	
                when '00G' {
                    // If the Case Owner is a queue we don't need to do anything
                    ownerChangeType = 'N2Q';
                }               
                when else  {ownerChangeType = 'ERR';}
            }
            System.debug('--*Case Ownership Change Type*--' + ownerChangeType);
        }
    }
	if(Trigger.isUpdate) {            
        for (Case newCase: Trigger.new) {
            Case oldCase = Trigger.oldMap.get(newCase.ID);
            // If the case owner has changed we need to run the case assignment logic 
            if(newCase.OwnerId  != oldCase.OwnerId ) { // Owner was changed
                String oldOwner = oldCase.OwnerId;
                String newOwner = newCase.OwnerId;
                switch on oldOwner.left(3) {
                    when '005' {		
                        // 005 means the previous owner was a user (not a queue)
                        switch on newOwner.left(3) {
                            when '005' {
                                ownerChangeType = 'U2U';
                                // New owner is a user to we need to point the case to the users Case_Assignment record
                                List<Case_Assignment__c> ca = [SELECT Id FROM Case_Assignment__c WHERE User__c = :newOwner limit 1 ];
                                if(ca != null && ca.size()>0){
                                    newCase.Case_Assignment__c = ca[0].Id;
                                } 
                                else {
                                    // If the new owner does not have a Case_Assignment record then set field to null
                                    newCase.Case_Assignment__c = null;
                                }
                            }
                            when '00G' {
                                // New owner is a queue (not a user) so set the Case_Assignment record to null
                                ownerChangeType = 'U2Q';
                                newCase.Case_Assignment__c = null;
                            }
                            when else  {ownerChangeType = 'ERR';}
                    	}
                    }
                    when '00G' {		
                        // 00G means previous owner is a queue
                        switch on newOwner.left(3) {
                            when '005' {
                                ownerChangeType = 'Q2U';
                                // New owner is a user to we need to point the case to the users Case_Assignment record
                                List<Case_Assignment__c> ca = [SELECT Id FROM Case_Assignment__c WHERE User__c = :newOwner limit 1 ];
                                if(ca != null && ca.size()>0){
                                    newCase.Case_Assignment__c = ca[0].Id;
                                } 
                                else {
                                    // If the new owner does not have a Case_Assignment record then set field to null
                                    newCase.Case_Assignment__c = null;
                                }
                            }
                            when '00G' {
                                // New owner is a queue (not a user) so set the Case_Assignment record to null
                                ownerChangeType = 'Q2Q';
                                newCase.Case_Assignment__c = null;
                            }
                            when else  {ownerChangeType = 'ERR';}
                    	}	 
                    }
                    when else {ownerChangeType = 'ERR';}
                }            
            }
            else {ownerChangeType = 'UNC'; }  // unchanged
            System.debug('--*Case Ownership Change Type*--' + ownerChangeType);
    	}
	}
    if(Trigger.isDelete){
        for (Case oldCase: Trigger.old) {
            oldOwner = oldCase.OwnerId;
            switch on oldOwner.left(3) {
                when '005' {ownerChangeType = 'U2D';}	
                when '00G' {ownerChangeType = 'Q2D';}
                when else  {ownerChangeType = 'ERR';}
            }
            System.debug('--*Case Ownership Change Type*--' + ownerChangeType);
        }
    }
}