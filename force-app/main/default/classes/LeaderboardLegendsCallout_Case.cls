/*================================================================================================
** Description   : This class contains method(s) which pushes data from Salesforce 
                   into the gateway when a process flow for Cases is triggered.
** Created By    : Manu Shrivastava, ECAS - Infosys Limited.
** Updated By    : Gabriel Hirakawa - Mivation
** Created On    : 10 January 2019
** Updated On    : 11 September 2020
==================================================================================================*/

public class LeaderboardLegendsCallout_Case{

    /*=================================================================================================
    ** Description : This Method is invoked from Process Builder. 
    ** Method Name : invokedFromPB
    ** Return Type : Void
    ** Parameters  : List of Case IDs
    ** Contributor : Manu Shrivastava, ECAS - Infosys Limited., Gabriel Hirakawa - Mivation
    ** Comments    : InvocableMethod annotation is used to expose this method to process builder
    ==================================================================================================*/

    @InvocableMethod
    public static void invokedFromPB(GatewayRequest[] requests){
        if(!requests.isEmpty()){
            for (GatewayRequest gwRequest : requests) {
                futureCalloutHandler(gwRequest.gatewayCaseId, gwRequest.activityType, gwRequest.voidBool);
            }
        } else {
            System.debug('[LL-CaseCallout] [Error] Request List is empty!');
        }
    }
    
    /*=========================================================
    ** Description : This method handle all the callout(s)
    ** Method Name : futureCalloutHandler
    ** Return Type : Void
    ** Parameters  : caseIdList
    ** Contributor : Manu Shrivastava, ECAS - Infosys Limited., Gabriel Hirakawa - Mivation
    ** Comments    : future method with callout true, this is done to make callout in asynchronus manner.
    ============================================================*/

    @future(callout=true)
    public static void futureCalloutHandler(Id caseId, String activityType, Boolean voidBool){
        // Query information of case, this is done here to insure that all information is up to date.
        Case[] caseList = [SELECT 
                           Id,
                           Owner.Id,
                           Owner.Username,
                           Owner.name,
                           Status,
                           Type,
                           Origin
                           FROM Case
                           WHERE ID = :caseId];
        makePostCallout(caseList, activityType, voidBool);
    }

    /*=======================================================
    ** Description : This method make post callout
    ** Method Name : makePostCallout
    ** Return Type : Void
    ** Parameters  : List<Case> caseList
    ** Contributor : Manu Shrivastava, ECAS - Infosys Limited., Gabriel Hirakawa - Mivation
    ** Comments    : This sends a request to the gateway 
                    and interprets it's response
    ============================================================*/ 

    public static void makePostCallout(Case[] IdList, String activityType, Boolean voidBool) {
        try {
            Mivation_Gateway__mdt gateway = [SELECT 
                                             MasterLabel, 
                                             API_Token__c, 
                                             Endpoint__c,
                                             Org_Unit__c
                                             FROM Mivation_Gateway__mdt 
                                             WHERE MasterLabel = 'Gateway'];
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            HttpResponse response = new HttpResponse();
            String jsonBody = generateJSONContent(IdList, activityType, voidBool, gateway.Org_Unit__c);
            request.setEndpoint(gateway.Endpoint__c);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', gateway.API_Token__c);
            request.setBody(jsonBody);
            request.setTimeout(120000);
            response = http.send(request);
            Integer responseCode = response.getStatusCode();
            if (responseCode == 202) {
                System.debug('[LL-CaseCallout] Successfully sent data to the mivation gateway! ID: ' + response.GetBody());
            } else if (responseCode == 204) {
                System.debug('[LL-CaseCallout] [Error] The request was properly formatted but the payload was empty');
            } else if (responseCode == 400) {
                System.debug('[LL-CaseCallout] [Error] The request was improperly formatted, did you set your format type?');
            } else if (responseCode == 401) {
                System.debug('[LL-CaseCallout] [Error] The request failed due to improper authorization, did you set your Bearer Token?');
            } else {
                System.debug('[LL-CaseCallout] [Error] The request failed due to an unknown error');
            }
        } catch(Exception e) {
            System.debug('[LL-CaseCallout] [Error] An unknown error occured while sending a request to the gateway');
        }
    }

    /*====================================================
    ** Description : This method prepare Integration request packet in JSON format
    ** Method Name : generateJSONContent
    ** Return Type : String 
    ** Parameters  : Case[] caseList
    ** Contributor : Manu Shrivastava, ECAS - Infosys Limited., Gabriel Hirakawa - Mivation
    ** Comments    : 
    =====================================================*/  
    
    static String generateJSONContent(Case[] caseList, String activityType, Boolean voidBool, String orgUnit) {
        // Create Unique Request ID
        // Blob b = Crypto.GenerateAESKey(128);
        // String h = EncodingUtil.convertToHex(b);
        // String requestId = h.SubString(0,8) + '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        // gen.writeStringField('request_id', requestId);
        gen.writeStringField('format', 'activity');
        gen.writeFieldName('payload');
        gen.writeStartArray();
        for (Case obj : caseList) {
            User owner = [SELECT Name, Email FROM User WHERE Id =:obj.OwnerId];
            gen.writeStartObject();
            gen.writeStringField('type', activityType);
            gen.writeDateTimeField('timestamp', DateTime.now());
            gen.writeStringField('id', obj.Id);
            gen.writeBooleanField('void', voidBool);
            gen.writeStringField('href', System.URL.getOrgDomainUrl().toExternalForm() + '/' + obj.Id);
            gen.writeStringField('user_email', owner.Email);
            gen.writeStringField('case_status', obj.Status);
            gen.writeStringField('case_type', obj.Type);
            gen.writeStringField('org_unit', orgUnit);
            gen.writeBooleanField('void', voidBool);
            gen.writeEndObject();
        }
        gen.writeEndArray();
        gen.writeEndObject();

        return gen.getAsString();
    }
    
}