import { LightningElement, wire, api, track } from 'lwc';
import userNewPwd from '@salesforce/apex/resetPasswordController.userNewPwd';

export default class NewPasswordComponent extends LightningElement {
    //@wire(getUserValues) users;
    newPwdInfos = {};
    parameters = {};
    userId = '';
    @track isLogged;
    @api userData= [];
    @track error;

    connectedCallback() {
        this.parameters = this.getQueryParameters();
        console.log(this.parameters);
        this.userId = this.parameters["Id"];
        console.log("UserId :" +this.userId);
        this.isLogged = this.getLoggedSession();
        console.log("IsLogged: "+this.isLogged);
    }

    getQueryParameters() {

        var params = {};
        var search = location.search.substring(1);

        if (search) {
            params = JSON.parse('{"' + search.replace(/&/g, '","').replace(/=/g, '":"') + '"}', (key, value) => {
                return key === "" ? value : decodeURIComponent(value)
            });
        }
        return params;
    }

    getLoggedSession() {

        var Login = false;

        if (this.userId != null) {
            Login = true;
        }
        return Login;
    }

    validateNewPassword(event) {
        this.errorMessage = null;
        let inputFields = this.template.querySelectorAll("input");
        let isNewPasswordError = false;
        let isNewPasswordConfirmError = false;

        inputFields.forEach(function (inputElement) {
            if (inputElement.name == 'newPassword') {
                console.log('user: ' +inputElement.value);
                if (inputElement.value == null || inputElement.value == '') isNewPasswordError = true;
                this.newPwdInfos['newPassword'] = inputElement.value;
            }
            else if (inputElement.name == 'newPasswordConfirm') {
                console.log('newPasswordConfirm: ' +inputElement.value);
                if (inputElement.value == null || inputElement.value == '') isNewPasswordConfirmError = true;
                this.newPwdInfos['newPasswordConfirm'] = inputElement.value;
            }
        }, this);
        if (!isNewPasswordError && !isNewPasswordConfirmError) this.performUserNewPwd();
        else {
            if (isNewPasswordConfirmError) {
                this.errorMessage = 'Username non valido';
                return;
            }
            if (isNewPasswordError) {
                this.errorMessage = 'Codice Univoco non valido';
                return;
            }

        }
    }

    performUserNewPwd() {
        let paramId ='';
        console.log('this.userId performUserNewPwd : ' +this.userId);

        userNewPwd({
            newPwdInfos:this.newPwdInfos,userId:this.userId
        })
            .then(result => {
                paramId = result;
                window.location.href = '/s/thankyoupage';
                console.log('PASSWORD CAMBIATA');
            })
            .catch(error => {
                console.log(error);
                this.errorMessage = error.body.message;

            });
    }


}