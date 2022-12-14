public with sharing class LWC_CommunityHelper {
    private static final String ORG_SUFFIX = '.force.rana';
    private static final String CUSTOMER_PROFILE_NAME = 'Customer User';
    private static final String TEMPLATE_NAME_COMMUNITY_REG = 'ConfirmRegistrationCommunity';
    private static final String PERSONACCOUNTNAME = 'Person Account';
    private static final String VERIFICAPAGEURLSUFFIX = '/s/verifica-utenza';
    private static final String EMAIL_OWA_RANA = 'noreply@rana.it';
    private static final String EMAIL_TEMPLATE_NAME = 'verify_User_new';

    public static Id getProfileId(String currentProfileName){
        return [SELECT Id FROM profile WHERE name =: currentProfileName ].Id;
    }

    public static Account getPossiblePersonAccount(String passedEmail){
        List<Account> retrievedAccount = [SELECT Id FROM Account WHERE personEmail =: passedEmail LIMIT 1];
        return retrievedAccount.isEmpty() ? new Account() : retrievedAccount.get(0);
    }

    public static void checkPasswordValidityAndEquality(String password, String confirmPassword){
        try{
            checkForRegex(password);
            checkForEquality(password, confirmPassword);
        }catch (Exception e) {
            throw e;
        }
    }

    private static void checkForRegex(String password){
        Pattern passwordRegex = Pattern.compile('^(?=.*\\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[a-zA-Z]).{8,}$');
        Matcher ismatch = passwordRegex.matcher( password );

        if( !ismatch.matches() ){
            throw new AuraHandledException('PasswordNotMatchRegex');
        }
    }

    private static void checkForEquality(String password, String confirmPassword){
        if(!confirmPassword.equals(password)){
            throw new AuraHandledException('passwordNotMacht');
        }
    }

    public static Id createPersonAccount(String name, String surname, String email, Date bDate ){
        System.debug('CreatePersonAccount');
        try {
            Account newPersonAccount = getPossiblePersonAccount(email);
            if(newPersonAccount.Id == null){
                newPersonAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(PERSONACCOUNTNAME).getRecordTypeId();
                newPersonAccount.personEmail = email;
            }

            newPersonAccount.FirstName = name;
            newPersonAccount.LastName = surname;
            newPersonAccount.PersonBirthdate = bDate;

            upsert newPersonAccount;
            System.debug('new PA: ' + newPersonAccount);
            return newPersonAccount.Id;
        } catch (Exception e) {
            throw e;
        }
    }

    public static boolean checkUser(String email){
		List<User> userToCheck = new List<User>();
		try {
			userToCheck = [SELECT Id, Name, Username, Email
                           FROM User
                           WHERE Email =: email];
			if (userToCheck.size() > 0) {
                return true;
			}
            return false;
		} catch (DmlException ex) { throw new AuraHandledException(ex.getMessage()); }
          catch (Exception e) { throw e; }
	}


    public static LWC_CommunityController.wrapperUser createUser(String email, String name, String surname, String password, String confirmPassword, boolean mrkCheck, Account createdAcc){
		System.debug('RanaCommunityController');

        LWC_CommunityController.wrapperUser returnWrap = new LWC_CommunityController.wrapperUser();

        String exceptionText;

        Id customerProfileUserId = getProfileId(CUSTOMER_PROFILE_NAME);

		try{
            User newUser = new User();
            newUser.username = email ;
            newUser.email = email;
            newUser.lastName = surname;
            newUser.firstName = name;
            newUser.ContactId = createdAcc.personContactId;

            String alias = name + surname;
            String networkId =  Network.getNetworkId();
            
            List<Network> communityPrefix = [Select UrlPathPrefix, Name from Network where Id = :networkId];
            System.debug(communityPrefix);
            String communityName;
            /* if (communityPrefix.size() > 0 && communityPrefix[0].UrlPathPrefix == 'ecommerce'){
                newUser.Consent_Newsletter_Ecommerce__c = mrkCheck;
                newUser.Last_Newsletter_Ecommerce_Update__c = Date.today();
                newUser.Registration_Source__c = 'ECOMMERCE';
                communityName = 'ecommerce';
            } else {
                newUser.Consent_Newsletter_Coupon__c = mrkCheck;
                newUser.Last_Newsletter_Coupon_Update__c = Date.today();
                newUser.Registration_Source__c = 'COUPON';
                communityName = 'coupon';

            } */

            //Alias must be 8 characters or less
            if(alias.length() > 8) {
                alias = alias.substring(0, 8);
            }
            newUser.alias = alias;
            // Creazione nickname per la commynity
            newUser.CommunityNickname = email.split('@')[0] + String.valueOf(Crypto.getRandomInteger());
            newUser.languagelocalekey = 'it';
            newUser.localesidkey = 'it';
            newUser.emailEncodingKey = 'UTF-8';
            newUser.timeZoneSidKey = 'Europe/Rome';
            newUser.profileId = customerProfileUserId;

            returnWrap.userCreated = newUser;

            String verificationId;

            if(!Test.isRunningTest()) {
                System.debug('PASSWORD: ' + password);
                System.debug('CONFIRMPASSWORD: ' + confirmPassword);
                System.debug(confirmPassword);
                Site.validatePassword(newUser, password, confirmPassword);
                newUser.id = Site.createExternalUser(newUser, createdAcc.Id, password,false);
            }else{
                insert newUser;

            }
            freezeUser(newUser.Id);
            sendEmailForVerification(newUser.Id,Site.getBaseUrl()+VERIFICAPAGEURLSUFFIX, communityName);
			return returnWrap;
		} catch (Exception e){
			System.debug('[EXCEPTION]::[RanaCommunityControlle]::[createUser]:: ' + e.getMessage());
			System.debug('[EXCEPTION]::[RanaCommunityControlle]::[createUser]:: ' + e.getStackTraceString());
			throw new AuraHandledException('Error during user creation, ' + e.getMessage());
		}
	}

    public static void freezeUser( String userID ){
        UserLogin userLog = getuserLogin(userID);
        userLog.IsFrozen = true;
        update userLog;
    }

    public static void unfreezeUser( String userID ){
        UserLogin userLog = getuserLogin(userID);
        userLog.IsFrozen = false;
        update userLog;

        if(!test.isRunningTest()) update new User(Id = userLog.UserId, Verified__c = true);
    }

    public static UserLogin getuserLogin( String userID ){
        UserLogin userLog = [SELECT IsFrozen, UserId
                             FROM UserLogin
                             WHERE UserId = : userID];
        return userLog;
    }

    /* public static void updateRelatedContact(String contId, Boolean userMarketingChoice){
        update new Contact(Id = contId, Consent_Newsletter_Coupon__c = userMarketingChoice);
    } */

   
     
    @future
    public static void sendEmailForVerification(String currentUserId,String verificationLink, String communityName){

        User currentUser = [SELECT Id, Name, Username, Email, FirstName, LastName
                            FROM User
                            WHERE Id =: currentUserId];

        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
        Map<String,String> templateNameMap = new Map<String,String>();

        OrgWideEmailAddress owea;

        System.debug('communityName' + communityName);
            try{
                 owea = [SELECT Id, Address, DisplayName
                         FROM OrgWideEmailAddress
                         WHERE Address = :EMAIL_OWA_RANA ];


                EmailTemplate verifEmailTemplate = [SELECT Id,Subject,Description,HtmlValue,DeveloperName,Body
                                                    FROM EmailTemplate
                                                    WHERE DeveloperName = :EMAIL_TEMPLATE_NAME];


                
                String params='?uid='+currentUser.Id;

                messages.add(buildEmail(verifEmailTemplate, owea, verificationLink+params, currentUser, communityName));
                if(!Test.isRunningTest()){
                    if(messages.size() > 0 ){
                        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                    }
                }
            }catch(exception ex){
               System.debug('send email fail: ' + ex.getMessage() );
            }
        }



    
    private static Messaging.SingleEmailMessage buildEmail(EmailTemplate template, OrgWideEmailAddress owea, String verifPageLink, User currentUser, String communityName){
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        String str = template.HtmlValue;
        str = str.replace('{!Verification_Link}', verifPageLink);
        str = str.replace('{!User.Name}', currentUser.FirstName);

        System.debug('communityName buildEmail' + communityName);

      /*   if(communityName.equals('coupon')){
        	message.setSenderDisplayName('Buoni Sconto Giovanni Rana');
        } 

        message.setSubject(template.subject);
        message.setHtmlBody(str);
        message.setUseSignature(false);
        message.setBccSender(false);
        if(!Test.isRunningTest()){
        message.setOrgWideEmailAddressId(owea.Id);
        message.toAddresses = new String[] {currentUser.Email};
        }

*/
        return message;
    }


    @AuraEnabled
    public static String getCommunityUrl(){
        String callbackUrl = '';
        /* try{
            if(!Test.isRunningTest()){
                String communityPrefix = [ SELECT UrlPathPrefix FROM Network WHERE Id =: Network.getNetworkId() LIMIT 1 ].UrlPathPrefix;
                callbackUrl = [ SELECT Id, homeUrl__c FROM Community_Url__mdt WHERE prefix__c =: communityPrefix LIMIT 1 ].homeUrl__c;
            }
           
        } catch (Exception exc) {
            throw new AuraHandledException('ID_LWC_RanaCommunityHelper - getCommunityUrl:: ' + exc.getLineNumber() + ' - ' + exc.getMessage());
        } */
        return callbackUrl;
    }
}