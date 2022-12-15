public class sendEmailController {

    @InvocableMethod(label='Send an email from apex class' description='sends an email')

public static void  sendEmailFunction(List<Request> request) {

    List<EmailTemplate> et = [
      SELECT Id, Description, DeveloperName, Body,HtmlValue,subject
      FROM EmailTemplate
      WHERE DeveloperName = :request[0].templateName AND isActive = TRUE
      LIMIT 1
    ];
    system.debug('templateid: '+et[0].id);

    String nomeDocumento = Request[0].documentName;
    String tipoInvio = Request[0].actionType;
    system.debug('nomeDocumento: '+nomeDocumento);
    system.debug('tipoInvio: '+tipoInvio);

    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
    if (nomeDocumento != null) {
      Document doc = [SELECT id, Body, Name FROM Document WHERE Name =: nomeDocumento];

      efa.setFileName(doc.Name);
      efa.setBody(doc.Body);
    }
    Case getEmail = [SELECT Id,ContactEmail,ThreadId__c,Contact.Name,CaseNumber,Reason,NotCompliant__c FROM Case WHERE id =: request[0].recordId];
    if(getEmail.ContactEmail != null) {
        String toaddress = getEmail.ContactEmail;
        system.debug(getEmail);

    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
    String str = et[0].HtmlValue;
    if(tipoInvio != 'Chiusura'){
        str = str.replace('{!Case.CaseNumber}', getEmail.CaseNumber);
        str = str.replace('{!Case.Contact}', getEmail.Contact.Name);
        str = str.replace('{!Case.Reason}', getEmail.Reason);
        str = str.replace('{!Case.NotCompliant__c}', getEmail.NotCompliant__c);
        }
    else{
        str = str.replace('{!Case.CaseNumber}', getEmail.CaseNumber);
        str = str.replace('{!Case.Contact}', getEmail.Contact.Name);
        str = str.replace('{!Case.Reason}', getEmail.Reason);
        }

     String[] toAddresses = new String[] {toaddress};
    String[] ccAddresses = new String[] {toaddress};
    message.setTemplateId(et[0].Id);
    message.setToAddresses(toAddresses);
    message.setCcAddresses(ccAddresses);
    message.setReplyTo('testanagraficavieste@outlook.com');
    message.setSenderDisplayName('Comune di Vieste');
    message.setSubject(et[0].subject +' '+ getEmail.ThreadId__c);
    message.setBccSender(false);
    message.setUseSignature(false);
    message.setWhatId(getEmail.id);
    message.setHtmlBody(str);
    if (nomeDocumento != null) {
    message.setFileAttachments(new Messaging.EmailFileattachment[]{efa});
    }

    Messaging.SingleEmailMessage[] messages = new List <
    Messaging.SingleEmailMessage > {message};
    Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
    }
   }

   public class Request {
    @invocableVariable
    public String recordId;
    @invocableVariable
    public String templateName;
    @invocableVariable
    public String subject;
    @invocableVariable
    public String contactId;
    @invocableVariable
    public String documentName;
    @invocableVariable
    public String actionType;
  }
}