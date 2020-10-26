import { LightningElement, api, track } from 'lwc';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled }  from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class rc_ConsentEventListener extends LightningElement {
    
    subscription = {};
    @api channelName = '/event/ConsentEvent';

    // init the component
    connectedCallback() {       
        // Register error listener     
        this.registerErrorListener();
        this.handleSubscribe();
    }

    // subscribe
    handleSubscribe() {
       
        // Callback invoked whenever a new event message is received
        const thisReference = this;
        const messageCallback = function(response) {
            console.log('rc_ConsentEventListener >> event received: ', JSON.stringify(response));
            
            var obj = JSON.parse(JSON.stringify(response));
            var payload = obj.data.payload;    
            var newValues = JSON.parse(payload.NewValues);      
                        
            var msg = 'Object: ' + payload.ObjectName + ', ChangeType: ' + payload.ChangeType;
            console.log('rc_ConsentEventListener >> msg: ', msg);

            const evt = new ShowToastEvent({
                title: 'Consent Event!',
                message: msg,
                variant: 'success',
            });

            msg += ', New Values: ';           
            const keys = Object.keys(newValues);
            keys.forEach((key, index) => {
                console.log(`[${key}: ${newValues[key]}]`);
                msg += `[${key}: ${newValues[key]}]`;
            });
            //lastEventMsg = msg;
            console.log('rc_ConsentEventListener >> lastEventMsg: ', msg);

            thisReference.dispatchEvent(evt);
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then(response => {
            // Response contains the subscription information on subscribe call
            console.log('rc_ConsentEventListener >> Subscription request sent to: ', JSON.stringify(response.channel));
            this.subscription = response;
        });
    }

    /* In case you want to unsubscribe use this
    // Handles unsubscribe button click
    handleUnsubscribe() {

        // Invoke unsubscribe method of empApi
        unsubscribe(this.subscription, response => {
            console.log('unsubscribe() response: ', JSON.stringify(response));
            // Response is true for successful unsubscribe
        });
    }
    */
   
    registerErrorListener() {
        // Invoke onError empApi method
        onError(error => {
            console.log('rc_ConsentEventListener >> error: ', JSON.stringify(error));
            // Error contains the server-side error
        });
    }
}