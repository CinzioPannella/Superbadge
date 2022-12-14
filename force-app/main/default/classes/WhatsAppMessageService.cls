public class WhatsAppMessageService {
    @AuraEnabled
   // Method to perform callouts
   public Static void makeCallout(string mobileno, string message){
       JSON2Apex ja;
       // define a response to caller
       final String fromNumber = '+3663261135'; 
       // define basic information for later, store these in a protected custom setting
       string resource = 'Messages.json';
       //Once you click Dashboard in the Twilio Sandbox on right hand side, you will be able to find account SID and auth Token
       string username = 'ACc8f249e482ab93ef9e467d5d22f97fdb'; 
       string password = 'd7045c1f5a2af82fcd25f25adaa04d2f';
       string method = 'POST';  
       string endpoint = 'https://api.twilio.com/2010-04-01/Accounts/'+username+'/'; 
    
       // check to ensure a callout can be performed using the Limits class. 
       if (Limits.getCallouts() >= Limits.getLimitCallouts()) {
           system.debug('Maximum number of callouts has been reached');
           
       // check for credentials error
       } else if (endpoint == null || username == null || password == null) {
           system.debug('Please verify your API Credentials');
           
       // configure and perform the callout
       } else {
           // define transaction variables
           HttpRequest req = new HttpRequest();
           HttpResponse res = new HttpResponse();
           Http h = new Http();
           
           // Configure the request
           req.setEndpoint(endpoint + resource);
           req.setMethod(method);
           req.setTimeout(120000);
           
           // Add basic authentication to header
           // Create blob of user:pass
           Blob headerValue = Blob.valueOf(username + ':' + password);
           // Base 64 Encode the blob and prepend "Basic "
           String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
           // Add the basic auth string to the Request Header
           req.setHeader('Authorization', authorizationHeader);            
   
           // Configure standard headers
           // This tells the API that we are sending and receiving the data as a JSON object 
           req.setHeader('Content-Type', 'application/json');
           req.setHeader('Content-Type','application/x-www-form-urlencoded');
           if(mobileno != null)
           {
            string jsonString='From='+EncodingUtil.urlEncode(fromNumber, 'UTF-8')+'&Body='+EncodingUtil.urlEncode(message, 'UTF-8')+'&To='+EncodingUtil.urlEncode('whatsapp:'+mobileno+'', 'UTF-8')+'';
               req.setBody(jsonString);    
           // Attempt the callout - create return error on exception
           try {
               // Perform callout and set response
               res = h.send(req);
               System.debug(res.getBody());
               // check response 
               if ((res.getStatusCode() == 200 || res.getStatusCode() == 201) && res.getBody() != null && res.getBody() != null) {
                 // Deserialize the response untyped
                   system.debug('Twilio success message: '+ message);
                  ja =(JSON2Apex)json.deserialize(res.getBody(),JSON2Apex.class);
                   system.debug('Twilio success: '+ja.message);
               }
               else{
                       system.debug('Twilio failed');
                 }
               }
           catch (exception e) {
               // Unexpected exceptions will be caught here, like a deserialization error.
          system.debug('Error :'+e);
           }
       }
       }
   }
   public class JSON2Apex {
   
       public Integer code;
       public String message;
       public String more_info;
       public Integer status;
       
   }
   }