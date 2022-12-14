import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import userResetPwd from '@salesforce/apex/resetPasswordController.userResetPwd';
import { NavigationMixin } from 'lightning/navigation';


export default class ResetPasswordComponent extends LightningElement {
    @api redirectUrl;
    resetPwdInfos = {};
    loginDisabled = true;
    errorMessage;
    showSpinner = false

    connectedCallback() {
        document.addEventListener("keyup", function (event) {
            this.errorMessage = null;
            if (event.code === 13) {
                this.validateResetPassword();
            }
        });
    }

    validateResetPassword(event) {
        this.errorMessage = null;
        let inputFields = this.template.querySelectorAll("input");
        let isUsernameError = false;
        let isCodiceUnivocoError = false;

        inputFields.forEach(function (inputElement) {
            if (inputElement.name == 'username') {
                console.log('user: ' +inputElement.value);
                if (this.validateEmail(inputElement.value)) this.resetPwdInfos['username'] = inputElement.value;
                else {
                    isUsernameError = true;
                    return;
                }
            }
            else if (inputElement.name == 'codiceUnivoco') {
                console.log('codiceUnivoco: ' +inputElement.value);
                if (inputElement.value == null || inputElement.value == '') isCodiceUnivocoError = true;
                this.resetPwdInfos['codiceUnivoco'] = inputElement.value;
            }
        }, this);

        if (!isCodiceUnivocoError && !isUsernameError) this.performUserResetPwd();
        else {
            if (isUsernameError) {
                this.errorMessage = 'Username non valido';
                return;
            }
            if (isCodiceUnivocoError) {
                this.errorMessage = 'Codice Univoco non valido';
                return;
            }

        }
    }

    performUserResetPwd() {
        let paramId ='';

        userResetPwd({
            resetPwdInfos: this.resetPwdInfos
        })
            .then(result => {
                paramId = result;
                window.location.href = '/s/newpassword'+'?Id='+paramId;
            })
            .catch(error => {
                console.log(error);
                this.errorMessage = error.body.message;

            });
    }

    validateEmail(email) {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
    }
}