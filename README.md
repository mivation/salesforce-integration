# Mivation Gateway - Salesforce Integration
This project contains an example of a Salesforce Integration to the Mivation Gateway. You can learn more about the APIs used in the [integration-gateway](https://github.com/mivation/integration-gateway) repo.


# Installation
This example is recommended to be used in a fresh scratch-org to prevent potential conflicts.

_Note: You need to have signed into your deb hub using the CLI you can find the steps [here](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_cli_usernames_orgs.htm)_.

***Before installing please set the fields in `project-scratch-def.json`***

Open this project within terminal and run the following commands
```
sfdx force:org:create -f config/project-scratch-def.json -a <InsertScratchOrgAlias> --setdefaultusername
```
Once that is created you will be given an alias. You will need that alias to run the following command to open the org:
```
sfdx force:org:open -u <DevHubAlias>
```
To push the project to the org use this command:
```
sfdx force:source:push
```

# What is supported?
Out of the box we support two Objects and 3 unique activity types. Each activity type also supports voids natively.
* Opportunity
    * closed-won
        * This is triggered every time an opportunity enters the Closed Won stage
    * meeting-scheduled
        * This is triggered every time an opportunity enters the meeting-scheduled stage.
* Case
    * case-closed
        * This is triggered every time a Case enters a Closed status.


# How Does It Work?
This example utilizes Process Builder events with invocable Apex Classes. Process Builder is used to configure when an activity occurs. When the event occurs it triggers an invocable class which takes the variables configured in the flow as well as the details of the activity's record.

## Process Builder Configuration
For instance in this project we support Case Closed Events. If you navigate to Setup > Process Automation > Process Builder > LeaderboardLegends - Case Events
![Case Process Builder](/.github/images/case-process-builder.png)
In the first conditional box you will see we have a simple activity configured for when a Case is Closed. Once that case has closed it the invokes an Apex Class.
![Invocable Apex Configuration](/.github/images/case-invocable-apex.png)
In this action we have chosen to Call Apex. It calls the class and passes the following variables to it. You will notice that the variables in grey are *required* fields
* CaseIDs ([Record].Id)
    * We pass the Id of the case associated with the initial event.
* Activity Type (String)
    * This field is used by Leaderboard Legends to determine which points to assign. In this case we use `case-closed`.
* Void? (Bool) 
    * This boolean is used to determine whether or not this record should add or deduct to a users points. This is typically used in events where an activity no longer qualifies. In our case example we support voids on re-opened cases. 

## Void Configuration
In this screenshot you can see that after sending the information to the Gateway we also set a field called Previously Closed. In this example, we set this to true on every Case closed because if it does re-open we want to make sure that Case does not count as an additional point towards that user.
![Void Configuration](/.github/images/case-void-configuration.png)
If this case is modified in anyway, we will check the status of the case and if the Status is not closed but the `Previously Closed` field is `true` we will send `void=true` to the gateway which disqualifies that record from being scored, deducting a point.

# What's Included?
Included in this example is the following:
* Apex Classes
    * GatewayRequest
        * This class is used to receive the variables from the process builder flow.
    * LeaderboardLegendsCallout_Case
        * This class is used for sending any Case related activities to the Gateway. It is responsible for the compiling of the JSON and sending the HTTP POST request to the gateway. More information about the API can be found at the [integration-gateway](https://github.com/mivation/integration-gateway) repo.
    * LeaderboardLegendsCallout_Opportunity
        * This class is used for sending any Opportunity related activities to the Gateway. It is responsible for the compiling of the JSON and sending the HTTP POST request to the gateway. More information about the API can be found at the [integration-gateway](https://github.com/mivation/integration-gateway) repo.
* Custom Metadata Record
    * This custom metadata record is used to store Gateway Credentials. These fields can be requested from your Account Executive. It has 3 fields associated with it:
        * API Token - String
            * This is the bearer token with authorization to post to the gateway.
            * Example: `Bearer AAAAAAAAAAAAAAAAAAAAAMLheAAAAAAA0%2BuSeid%2BULvsea4JtiGRiSDSJSI%3DEUifiRBkKG5E2XzMDjRfl76ZC9Ub0wnz4XsNiRVBChTYbJcE3F`
        * Endpoint - String
            * The endpoint of the Mivation Gateway.
            * Example: `https://gateway.sandbox.mivation.com`
        * Org Unit
            * This field is used to determine which organization these records belong to
            * Example: `acme-west`
* Custom Fields
    * Case
        * Previously_Closed__c - Checkbox
            * This field is used to determine whether or not a record is a void.
    * Opportunity
        * Previously_Closed_Won__c - Checkbox
            * This field is used to determine whether or not a record is a void.
        * Previously_Meeting_Scheduled__c - Checkbox
            * This field is used to determine whether or not a record is a void.
* Custom Objects
    * Mivation_Gateway_mdt - Custom Metadata Object
        * The fields are the same as the custom metadata record above. This object is where the metadata record lives.

# How do I add support for Custom Fields?
In order to add a custom field you would go to the callout associated with the object. For this example, we will use Case. Let's say we add a new checkbox field called `Referral_Mentioned__c`. This field will be utilized to signify whether or not the support representative mentioned referrals. To add support for this you must do 2 things: Add custom field to SOQL query on the record, and add the field to the JSON generator. See Below:
## Adding Field To SOQL Query
![Custom Field SOQL Query](/.github/images/custom-field-soql-query.gif)

## Adding Field To JSON Generator
![Custom Field JSON Generator](/.github/images/custom-field-json-generator.gif)

Once these fields are added, you're good to go!

---

# License Conditions
The example code in this repository is made available, by Mivation, under the MIT License.  The Mivation products and systems that the example code integrates with, including, but without limitation to: Mivation Gateway, RacingSnail and Leaderboard Legends are the sole and exclusive property of Mivation to which Mivation owns all right, title and interest in and to the intellectual property rights therein and they are licensed separately and not included in the MIT License covering this example code.  The Salesforce CRM system, including the Force.com platform and Apex language, are the property of Salesforce.com, Inc and are also licensed separately. 





