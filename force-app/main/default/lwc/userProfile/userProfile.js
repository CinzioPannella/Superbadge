import { LightningElement, wire, api, track } from 'lwc';
import getUserValues from '@salesforce/apex/LoginController.userValues';
import getCases from '@salesforce/apex/LoginController.userCases';

const columns = [
    {
        label: 'Numero Caso',
        fieldName: 'CaseNumber'
    }, {
        label: 'Stato Lavorazione',
        fieldName: 'Status'
    }, {
        label: 'Data Creazione',
        fieldName: 'CreatedDate'
    }
];

export default class UserProfile extends LightningElement {
    @wire(getUserValues) users;
    @wire(getCases) cases;
    parameters = {};
    userId = '';
    @api userData= [];
    @api caseData= [];
    @track error;
    @track userFirstName = '';
    @track userLastName = '';
    @track userUserName = '';
    @track userCodiceUnivoco = '';
    @track columns = columns;
    @track isCase = false;

    connectedCallback() {
        this.parameters = this.getQueryParameters();
        console.log(this.parameters);
        this.userId = this.parameters["Id"];
        console.log(this.userId);
        this.getUserValuesFromApex();
        this.getCasesFromApex();
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

    getUserValuesFromApex(){
        console.log('getUserValuesFromApex');
		getUserValues({ recordId: this.userId})
		.then((results) => {
			this.userData = results;
            this.userFirstName = results.FirstName;
            this.userLastName = results.LastName;
            this.userUserName = results.Username;
            this.userCodiceUnivoco = results.codiceUnivoco__c;
            console.log('RECORD: '+JSON.stringify(this.userData));
		})
		.catch((error) => {
			this.userData = [];
			console.error(error);
		});
	}

    getCasesFromApex(){
        console.log('getCasesFromApex');
        getCases({ recordId: this.userId})
        .then((results) => {
            this.caseData = results;
            if(this.caseData.length > 0){
                this.isCase=true;
            }else{
                this.isCase=false;
            }
            this.error = undefined;
            console.log('getCases: '+JSON.stringify(this.caseData));
        })
        .catch((error) => {
			this.caseData = [];
			console.error(error);
		});
    }
}