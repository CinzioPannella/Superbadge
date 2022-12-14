public without sharing class LoginController {

	@AuraEnabled
	public static String userLogin(Map<String, String> loginInfos){
		try{
			String login = doLogin(loginInfos);
			return login;
		} catch (Exception e){
			throw e;
		}
	}

	private static String doLogin(Map<String, String> loginInfos){
		String username = loginInfos.get('username').trim();
		String password = loginInfos.get('password').trim();
		String userId;

			if (Site.isLoginEnabled() || Test.isRunningTest()){
				if (Site.isValidUsername(loginInfos.get('username'))){
					System.debug(loginInfos.get('username'));
					User inactiveUser = [SELECT Id,name,LoginPwd__c,Username
										FROM User
										WHERE Username =:username LIMIT 1];
					if(inactiveUser == null ){
						throw new AuraHandledException('User not found');
					}
					System.debug('password: '+ password);
					if(!inactiveUser.LoginPwd__c.equals(password)){
						throw new AuraHandledException('wrong password');
					}
					//PageReference startUrl = null;
					try{
						if(inactiveUser.LoginPwd__c.equals(password) && inactiveUser.username == username){
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

	@AuraEnabled(cacheable = true)
    public static User userValues(Id recordId) {
		User retrievedUser = new User();
	
		try {
			retrievedUser = [SELECT Firstname, Lastname, Username, codiceUnivoco__c 
								FROM User 
								WHERE Id = :recordId LIMIT 1];
		}
		catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return retrievedUser;
    }

	@AuraEnabled(cacheable=true)
	public static List<Case> userCases(Id recordId) {
		User retrievedUser = new User();
		List<Case> caseList = new List<Case>();

		try {
			retrievedUser = [SELECT Id, contact.Accountid
								FROM User 
								WHERE Id = :recordId LIMIT 1];

		String AccountIdfromUser = retrievedUser.contact.AccountId;
		System.debug('AccountIdfromUser: '+AccountIdfromUser);

		caseList = [SELECT id,CaseNumber,Status,CreatedDate 
							FROM Case 
							WHERE AccountId =: AccountIdfromUser];
		}
		catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

		return caseList;
	}
}