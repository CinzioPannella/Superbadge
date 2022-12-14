import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import userLogin from '@salesforce/apex/LoginController.userLogin';
import { NavigationMixin } from 'lightning/navigation';
import property from '@salesforce/user/isGuest';
import { CurrentPageReference } from 'lightning/navigation';

export default class LoginComponent extends NavigationMixin(LightningElement) {
    @api redirectUrl;
    loginInfos = {};
    loginDisabled = true;
    errorMessage;
    showSpinner = false

    connectedCallback() {
        document.addEventListener("keyup", function (event) {
            this.errorMessage = null;
            if (event.code === 13) {
                this.login();
            }
        });
    }

    login(event) {
        this.errorMessage = null;
        let inputFields = this.template.querySelectorAll("input");
        let isUsernameError = false;
        let isPasswordError = false;

        inputFields.forEach(function (inputElement) {
            if (inputElement.name == 'username') {
                console.log('user: ' +inputElement.value);
                if (this.validateEmail(inputElement.value)) this.loginInfos['username'] = inputElement.value;
                else {
                    isUsernameError = true;
                    return;
                }
            }
            else if (inputElement.name == 'password') {
                console.log('password: ' +inputElement.value);
                if (inputElement.value == null || inputElement.value == '') isPasswordError = true;
                this.loginInfos['password'] = inputElement.value;
            }
        }, this);

        if (!isPasswordError && !isUsernameError) this.performUserLogin();
        else {
            if (isUsernameError) {
                this.errorMessage = 'Username non valido';
                return;
            }
            if (isPasswordError) {
                this.errorMessage = 'Password non valida';
                return;
            }

        }
    }

    performUserLogin() {
        let paramId ='';

        userLogin({
            loginInfos: this.loginInfos
        })
            .then(result => {
                paramId = result;
                window.location.href = '/s/user-profile'+'?Id='+paramId;
            })
            .catch(error => {
                console.log(error);
                this.errorMessage = error.body.message;

            });
    }

    validateEmail(email) {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}