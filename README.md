# Mivation Gateway - Salesforce Integration
This project contains an example of a Salesforce Integration to the Mivation Gateway. You can learn more about the APIs used in the [integration-gateway](https://github.com/mivation/integration-gateway) repo.


# Installation

## Requirements
* Enterprise Edition or higher
* Salesforce CLI [Installation Instructions](https://developer.salesforce.com/docs/atlas.en-us.248.0.sfdx_setup.meta/sfdx_setup/sfdx_setup_install_cli.htm)

This is an example integration which provides a barebone implementation of the Mivation Gateway's activity format.

It is recommended that you first deploy this to a Sandbox or a Scratch org

<sub>_Note: It is not necessary to use a scratch org, however, if you want to deploy it to a scratch org you will need to sign in to your Dev Hub account [here](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_cli_usernames_orgs.htm)_</sub>

First authorize and set a default org for your project, you can find more information [here](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_cli_usernames_orgs.htm)

Once authorized you can run the following command:
```sf project deploy start```
This will begin the deployment of the metadata contained in the project. Once deployed you can begin configuring the integration.

## Setup API Credentials
This integration contains Custom Metadata which is used to store the credentials for the integration.

1. Click on Setup
2. In the quick find box search 'Custom Metadata'
3. On the Mivation Gateway object select 'Manage Records'
4. Insert your API Credentials and click save.

## Enable Salesforce Flows
We provide 2 example Salesforce Flows. These provide support for Closed Cases and Closed Won opportunities. These will need to be enabled before any activities are sent to the Mivation Gateway. 

1. Click on Setup
2. In the quick find box search 'Flows'
3. In the list of flows look for `LeaderboardLegends - Push On Case Closed` and `LeaderboardLegends - Push On Closed Won`
4. On each of these flows select "Activate"

These flows assume the activity names "closed-case" and "closed-won" you can find these settings by selecting any of the Send To Gateway action elements within the Flow builder. 



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
This example utilizes Record-Triggered Flows with invocable Apex Classes. Flows is used to configure when an activity occurs. When the event occurs it triggers an invocable method which takes the variables configured in the flow as well as the pre-defined fields in the provided Apex Classes. 

## Flow Builder Configuration
For instance in this project we support Case Closed Events. If you navigate to Setup > Process Automation > Flows > LeaderboardLegends - On Case Closed
![Case Flow Builder](/.github/images/case-flow-builder.png)
In the first conditional box you will see we have a simple activity configured for when a Case is Closed. Once that case has closed it the invokes an Apex Class.
![Invocable Apex Configuration](/.github/images/case-flow-invocable-apex.png)
In this action we have chosen to Call Apex. It calls the class and passes the following variables to it. You will notice that the variables in grey are *required* fields
* CaseIDs ([Record].Id)
    * We pass the Id of the case associated with the initial event.
* Activity Type (String)
    * This field is used by Leaderboard Legends to determine which points to assign. In this case we use `case-closed`.
* Void? (Bool) 
    * This boolean is used to determine whether or not this record should add or deduct to a users points. This is typically used in events where an activity no longer qualifies. In our case example we support voids on re-opened cases. 

## Void Configuration
In this screenshot you can see that after sending the information to the Gateway we also set a field called Previously Closed. In this example, we set this to true on every Case closed because if it does re-open we want to make sure that Case does not count as an additional point towards that user.
![Void Configuration](/.github/images/case-flow-void-configuration.png)
If this case is modified in anyway, we will check the status of the case and if the Status is not closed but the `Previously Closed` field is `true` we will send `void=true` to the gateway which disqualifies that record from being scored, deducting a point.

# What's Included?
Included in this example is the following:
* Apex Classes
    * GatewayRequest
        * This class is used to receive the variables defined in the Flow Builder.
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





