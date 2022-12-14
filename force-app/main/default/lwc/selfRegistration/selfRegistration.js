import { LightningElement , track, wire  } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
//import CustomStyle from '@salesforce/resourceUrl/CustomStyle';
//import ICON from '@salesforce/resourceUrl/GP_Icon';
import createCommUser from '@salesforce/apex/LWC_CommunityController.createCommunityUser';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
/* 
import First_name from '@salesforce/label/c.First_name';
import Last_name from '@salesforce/label/c.Last_name';
import Email from '@salesforce/label/c.Email';
import Password from '@salesforce/label/c.Password';
import Confirm_Password from '@salesforce/label/c.Confirm_Password';
import subscribe from '@salesforce/label/c.subscribe';
import marketing_activities from '@salesforce/label/c.marketing_activities';
import profiling_purposes from '@salesforce/label/c.profiling_purposes';
import Yes from '@salesforce/label/c.Yes';
import No from '@salesforce/label/c.No';
import Register from '@salesforce/label/c.Register';
import already_registered from '@salesforce/label/c.already_registered';
import pwdRules from '@salesforce/label/c.pwdRules';
import already_Exsist from '@salesforce/label/c.already_Exsist';
import fullfill_field from '@salesforce/label/c.fullfill_field';
import pwd_not from '@salesforce/label/c.pwd_not';
import pwd_not_equals from '@salesforce/label/c.pwd_not_equals';
import valid_email_address from '@salesforce/label/c.valid_email_address';
import unexpectedError from '@salesforce/label/c.unexpectedError';
import passwordTooEasy from '@salesforce/label/c.passwordTooEasy';
import torna_al_sito from '@salesforce/label/c.torna_al_sito'; */
import { CurrentPageReference } from 'lightning/navigation';

export default class selfRegistration extends LightningElement {
   // ranaLogo = ICON;
/* 
    @track label = {
        First_name, Last_name, Email, Password, Confirm_Password, subscribe, marketing_activities, profiling_purposes, Yes, No, Register, already_registered, pwdRules, already_Exsist, 
        fullfill_field, pwd_not, pwd_not_equals, valid_email_address, unexpectedError, passwordTooEasy,torna_al_sito
    }; */


    @track url;
    @track emailAlreadyExists = false; 
    @track existUser = false;
    @track checkGDPR = false;
    @track checkMKT = false;
    @track checkNewsletter = false;
    @track nextDisabled = true;
    @track marketingCheck = false;
    @track password = '';
    @track confermaPassword = '';
    @track email = '';
    @track name = '';
    @track surname = '';
    @track isLoaded = false;


    errorObj = {
        title: 'Errore',
        message: 'Non è stato possibile creare lo user',
        variant: 'error'
    }

    succObj = {
        title: "Registrazione Completata",
        message: "Adesso sarai reindirizzato alla pagina di login e riceverai una email di conferma!",
        variant: 'success'
    }

    warningObj = {
        title: 'warning',
        message: 'qualcosa è andato storto',
        variant: 'warning'
    }

    gdprConsent = false;
    newsletterConsent = false;
    newUser = {};

    currentPageReference = null; 
    urlStateParameters = null;
 
    /* Params from Url */
    urlId = null;
    retUrl = null;
    urlType = null;
 
   /*  @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        console.log("GETTING PARAMETERS");
       if (currentPageReference) {
          this.urlStateParameters = currentPageReference.state;
          this.setParametersBasedOnUrl();
       }
    }
 
    setParametersBasedOnUrl() {
       console.log("SETTING PARAMETER");
       console.log( this.urlStateParameters);

       this.retUrl = this.urlStateParameters.retUrl;

       

    } */

    
    @track sessoValues = [
        { label: 'Uomo', value: 'Uomo' },
        { label: 'Donna', value: 'Donna' }
    ];

    sexChange(event) {
        this.value = event.target.value;
        //console.log(this.value);
    }

    connectedCallback(){
        /* this.isLoaded = false;
        loadStyle(this, CustomStyle)
        .then(result => { console.log("style caricato")})
        .catch(error => { console.log('error loadstyle ', error)});
        this.isLoaded = true;
      
        if (window.location.href.indexOf("ecommerce") == -1){
           
            this.retUrl = "https://shop.giovannirana.it/"
        }
     */
        
    }
;
    get sesso() {
        return [
            { label: 'Uomo', value: 'Uomo' },
            { label: 'Donna', value: 'Donna' }
        ];
    }

    resetValidationIssues(){
            this.template.querySelector(`[data-id="nameError"]`).innerHTML = '';
            this.template.querySelector(`[data-id="surnameError"]`).innerHTML = '';
            this.template.querySelector(`[data-id="emailError"]`).innerHTML = '';
            this.template.querySelector(`[data-id="emailError"]`).innerHTML = '';
            this.template.querySelector(`[data-id="passwordError"]`).innerHTML = '';
            this.template.querySelector(`[data-id="passwordError"]`).innerHTML = '';
            this.template.querySelector(`[data-id="confirmPasswordError"]`).innerHTML = '';
            this.template.querySelector(`[data-id="personalDataCheckError"]`).innerHTML = '';
            this.template.querySelector(`[data-id="marketingCheckError"]`).innerHTML = '';
    }



    validateInput(){
        try {
            let validSoFar = true;
            this.resetValidationIssues();
            
            if (this.template.querySelector(`[data-id="Name"]`).value == "") {
                //console.log(this.template.querySelector(`[data-id="Name"]`).dataset.error);
                validSoFar = false;
                this.template.querySelector(`[data-id="nameError"]`).innerHTML = this.label.fullfill_field;
            }
            if (this.template.querySelector(`[data-id="Surname"]`).value == "") {
                validSoFar = false;
                this.template.querySelector(`[data-id="surnameError"]`).innerHTML = this.label.fullfill_field;
            }
            if (!this.validateEmail(this.template.querySelector(`[data-id="Email"]`).value)) {
                validSoFar = false;
                this.template.querySelector(`[data-id="emailError"]`).innerHTML = this.label.valid_email_address;
            }
            if (this.emailAlreadyExists == true) {
                validSoFar = false;
                this.template.querySelector(`[data-id="emailError"]`).innerHTML = this.label.already_Exsist;
            }
            if (this.template.querySelector(`[data-id="Password"]`).value == "") {
                validSoFar = false;
                this.template.querySelector(`[data-id="passwordError"]`).innerHTML = this.label.fullfill_field;
            }
            if(!this.validatePassword(this.template.querySelector(`[data-id="Password"]`).value)){
                validSoFar = false;
                this.template.querySelector(`[data-id="passwordError"]`).innerHTML = this.label.pwd_not;
            }
            if (!(this.template.querySelector(`[data-id="ConfermaPassword"]`).value == this.template.querySelector(`[data-id="Password"]`).value)) {
                validSoFar = false;
                this.template.querySelector(`[data-id="confirmPasswordError"]`).innerHTML = this.label.pwd_not_equals;
            }
            if (!this.checkGDPR) {
                validSoFar = false;
                this.template.querySelector(`[data-id="personalDataCheckError"]`).innerHTML = this.label.fullfill_field;
            }
            return validSoFar;
        } catch (error) {
            console.error(error);
        }
    }

    goNext(event){
        this.isLoaded = false;
        
        if(!this.validateInput()) {
            window.scrollTo(0, 0); // Object parameter
            this.isLoaded = true;
            return;
        };
        this.emailAlreadyExists = false;
        this.email = this.template.querySelector(`[data-id="Email"]`).value;
        this.name = this.template.querySelector(`[data-id="Name"]`).value;
        this.surname = this.template.querySelector(`[data-id="Surname"]`).value;
        this.password = this.template.querySelector(`[data-id="Password"]`).value;
        this.confermaPassword = this.template.querySelector(`[data-id="ConfermaPassword"]`).value;
        var _self = this;

        console.log(this.password);
        console.log(this.confermaPassword);
        createCommUser({
            email: this.email,
            name: this.name,
            surname: this.surname,
            bDate: this.bDate,
            password: this.password,
            confirmPassword: this.confermaPassword,
           // mrkCheck : this.marketingCheck
            mrkCheck : this.checkMKT

        }).then(
            result=> {

                _self.result = result;
                this.isLoaded = true;
                if(_self.result.userChecked){
                    this.emailAlreadyExists = true; 
                    _self.validateInput();
                    

                }else{
                                        
                    if (window.location.href.indexOf("ecommerce") == -1){
                       
                        window.location.replace('/s/thankyou');
                    } else {

                        window.location.replace('/ecommerce/s/thankyou');
                    }

                    
                    
                }                
            }
        ).catch(
            error => {
                //this.ShowToastEventHelper(this.errorObj);
                console.log('sono dentro a createpersonaccount error2:', error);
                console.log(error.body.message);
                let errorMEssage = this.label.unexpectedError;
                if(error.body.message.includes('too easy') || error.body.message.includes('troppo facile')){
                    errorMEssage = this.label.passwordTooEasy;
                }
                this.template.querySelector(`[data-id="backendError"]`).innerHTML = errorMEssage ;
                this.errorObj.message = errorMEssage;
                this.isLoaded = true;

                this.ShowToastEventHelper(this.errorObj)
                
                
            })        
    }

    validatePassword(password){ 
        var passw=  /^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[a-zA-Z]).{8,}$/;
        if(password.match(passw)){ 
            return true;
        }else { 
            return false;
            }
    }

    validateEmail(mail) {
        return /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/.test(mail);
    }

    resetInputErrors(event) {
        this.template.querySelector('[data-id="' + event.target.dataset.error + '"]').innerHTML = '';
        //console.log(JSON.stringify(event.target.dataset));
        this.emailAlreadyExists = false;
    }

    setGDPR(event){
        //console.log('cheheh:' , event.target.checked);
        this.checkGDPR = event.target.checked;
        this.nextDisabled = !event.target.checked;
    }

    setMKT(event){
        this.checkMKT = event.target.checked;
        
    }
    setNewsletter(event){
        this.checkNewsletter = event.detail.checked;
    }

    returnLogIn(){

        if (window.location.href.indexOf("ecommerce") == -1){
                       
             window.location.href = window.location.origin + '/s/login';
        } else {

            window.location.href = window.location.origin + '/ecommerce/s/login';
        }
       
    }


    ShowToastEventHelper( obj){
        const evt = new ShowToastEvent({
            title: obj.title,
            message: obj.message,
            variant: obj.variant,
        });

        console.log(obj);
        try {
            this.dispatchEvent(evt);
        } catch (error) {
            console.log(error);

        }
    }

    getMarketing(event){
        //console.log('data mrk: ' + event.target.dataset.value);
        this.marketingCheck = event.target.dataset.value;
        //console.log(this.marketingCheck);
    }

    

}