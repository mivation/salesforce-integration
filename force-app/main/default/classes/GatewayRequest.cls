global class GatewayRequest {
    
    public GatewayRequest() {
        
    }
    
    @InvocableVariable(label = 'ObjectId' required = true)
    public Id gatewayCaseId;
        
    @InvocableVariable(label = 'Activity Type' required = true)
    public String activityType;
    
    @InvocableVariable(label = 'Void?')
    public Boolean voidBool = false;
        
    @TestVisible
    GatewayRequest(Id gatewayCaseId, String activityType) {
        this.gatewayCaseId = gatewayCaseId;
        this.activityType = activityType;
    }
}