public with sharing class ForecastProjectRelatedListLWCController {

    @AuraEnabled(cacheable=true)
    public static List<ForecastDataWrapper> getProjectForecastData(String projectId){
        try {

            List<ForecastDataWrapper> forecastDataWrapperList = new List<ForecastDataWrapper>();

            List<RepliconForecast__c> forecastList = new List<RepliconForecast__c>();
            forecastList = [SELECT Id, Name, Contact__c, Contact__r.Name, EstimatedHours__c, EstimatedRevenue__c, Week_Start_Date__c
                                FROM RepliconForecast__c
                                WHERE Project__c =: projectId
                                ORDER BY Week_Start_Date__c ASC];

            for(RepliconForecast__c forecast : forecastList){

                ForecastDataWrapper newWrapper = new ForecastDataWrapper();
                newWrapper.forecastId = forecast.Id;
                newWrapper.forecastName = forecast.Name;
                newWrapper.forecastUrl = '/' + forecast.Id;
                newWrapper.employeeId = forecast.Contact__c;
                newWrapper.employeeName = forecast.Contact__r.Name;
                newWrapper.employeeUrl = '/' + forecast.Contact__c;
                newWrapper.estimatedHours = forecast.EstimatedHours__c;
                newWrapper.estimatedRevenue = forecast.EstimatedRevenue__c;
                newWrapper.forecastWeekStartDate = forecast.Week_Start_Date__c;
                String weekStartDatetime = Datetime.newInstance(forecast.Week_Start_Date__c.year(), forecast.Week_Start_Date__c.month(), forecast.Week_Start_Date__c.day()).format('MMM dd, yyyy');
                newWrapper.forecastWeekStartDateString = weekStartDatetime;
                forecastDataWrapperList.add(newWrapper);

            }

            return forecastDataWrapperList;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    public class ForecastDataWrapper{
        @AuraEnabled
        public Id forecastId {get;set;}
        @AuraEnabled
        public String forecastName {get;set;}
        @AuraEnabled
        public String forecastUrl {get;set;}
        @AuraEnabled
        public Id employeeId {get;set;}
        @AuraEnabled
        public String employeeName {get;set;}
        @AuraEnabled
        public String employeeUrl {get;set;}
        @AuraEnabled
        public Decimal estimatedHours {get;set;}
        @AuraEnabled
        public Decimal estimatedRevenue {get;set;}
        @AuraEnabled
        public Date forecastWeekStartDate {get;set;}
        @AuraEnabled
        public String forecastWeekStartDateString {get;set;}
    }
}