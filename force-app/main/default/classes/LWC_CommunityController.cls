public without sharing class LWC_CommunityController {
    private static final String STARTURL = '/s';
    //private static final String NETWORKID = Network.getNetworkId();

    @AuraEnabled
    public static wrapperUser createCommunityUser(String email, String  name, String surname, String password, String confirmPassword, Date bDate, boolean mrkCheck){
        wrapperUser wrapUser = new wrapperUser();
        LWC_CommunityHelper helper = new LWC_CommunityHelper();
        Savepoint beforeAllSavePoint = Database.setSavepoint();
        try {

            LWC_CommunityHelper.checkPasswordValidityAndEquality(password, confirmPassword);

            boolean checkedUser = LWC_CommunityHelper.checkUser(email);
            System.debug('checkedUser' + checkedUser);
            String verificationId;
            wrapUser.userChecked = true;
            if(checkedUser == false){
                Id personAccountId = LWC_CommunityHelper.createPersonAccount(name, surname, email, bDate);
                Account createdPersonAccount = [SELECT Id,PersonContactId FROM Account WHERE Id =: personAccountId];
                //LWC_CommunityHelper.updateRelatedContact(createdPersonAccount.PersonContactId, mrkCheck);
                wrapUser = LWC_CommunityHelper.createUser(email, name, surname, password, confirmPassword, mrkCheck, createdPersonAccount);
                wrapUser.userChecked = false;
                //TO DO:send verification email
            }


            return wrapUser;
        } catch (Exception e) {
            Database.rollback(beforeAllSavePoint);
            throw e;
        }
    }


    @AuraEnabled
    public static UserLogin verifyUser(String identifier){
        try{
            LWC_CommunityHelper.unfreezeUser(identifier);
            return LWC_CommunityHelper.getuserLogin(identifier);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Account updateAccount(Account account){
        try {
            User currentUser = [SELECT Id, Username, FirstName, LastName FROM User WHERE Id = :UserInfo.getUserId()];
            if (currentUser != null){
                currentUser.FirstName = account.FirstName;
                currentUser.LastName = account.LastName;
                update currentUser;
                update account;
            }
        } catch (Exception e) {
            throw new AuraHandledException('ID_LWC_RanaCommunityController - updateAccount' + ' - ' + e.getLineNumber() + ' - ' +  e.getMessage());
        }
        return account;
    }

    public class wrapperUser{
        @AuraEnabled public Boolean userChecked{get; set;}
        @AuraEnabled public User userCreated{get; set;}
        @AuraEnabled public String verificationId{get; set;}

        public wrapperUser(){
        }
    }
}