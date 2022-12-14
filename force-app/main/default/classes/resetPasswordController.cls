public without sharing class resetPasswordController {

    @AuraEnabled
	public static String userResetPwd(Map<String, String> resetPwdInfos){
		try{
			String resetPwd = doReset(resetPwdInfos);
			return resetPwd;
		} catch (Exception e){
			throw e;
		}
	}

    private static String doReset(Map<String, String> resetPwdInfos){
		String username = resetPwdInfos.get('username').trim();
		String codiceUnivoco = resetPwdInfos.get('codiceUnivoco').trim();
		String userId;

			if (Site.isLoginEnabled() || Test.isRunningTest()){
				if (Site.isValidUsername(resetPwdInfos.get('username'))){
					System.debug(resetPwdInfos.get('username'));
					User inactiveUser = [SELECT Id,name,LoginPwd__c,codiceUnivoco__c,Username
                                            FROM User
                                            WHERE Username =:username
                                            LIMIT 1];
					if(inactiveUser == null ){
						throw new AuraHandledException('Utente non trovato');
					}
					System.debug('codiceUnivoco: '+ codiceUnivoco);
					if(!inactiveUser.codiceUnivoco__c.equals(codiceUnivoco)){
						throw new AuraHandledException('Codice Univoco Errato');
					}
					try{
						if(inactiveUser.codiceUnivoco__c.equals(codiceUnivoco) && inactiveUser.username == username){
								System.debug('SEI ENTRATO!');
								userId = inactiveUser.Id;
						}else{
							System.debug('SEI FUORI!');
							userId = null;
						}
					}
					catch (Exception ex){
						System.debug('ERRORE!');
					}
				}
			}
		return userId;
    }

    @AuraEnabled
	public static String userNewPwd(Map<String, String> newPwdInfos,string userId){
		try{
			String newPwd = setNewPwd(newPwdInfos,userId);
			return newPwd;
		} catch (Exception e){
			throw e;
		}
	}

    private static String setNewPwd(Map<String, String> newPwdInfos, string userId){
		System.debug('newpwdinfos: '+ newPwdInfos);
		String newPasswordConfirm = newPwdInfos.get('newPasswordConfirm').trim();
		String newPassword = newPwdInfos.get('newPassword').trim();

			if (Site.isLoginEnabled() || Test.isRunningTest()){
					System.debug(newPwdInfos.get('newPassword'));
					User inactiveUser = [SELECT Id,name,LoginPwd__c,codiceUnivoco__c,Username
                                            FROM User
                                            WHERE id =:userId
                                            LIMIT 1];
					if(inactiveUser == null ){
						throw new AuraHandledException('Utente non trovato');
					}
                    else{
						inactiveUser.LoginPwd__c = newPassword;
						update inactiveUser;
                    }
			}
		return userId;
    }
}