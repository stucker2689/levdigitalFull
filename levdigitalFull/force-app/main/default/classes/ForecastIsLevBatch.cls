/**
 * Created 6/6/2022 ST
 * 
 * Purpose to populate the Is_Lev_Forecast__c field on existing Forecasts
 * 
 * Run with: 
ForecastIsLevBatch newBatch = new ForecastIsLevBatch();
Database.executeBatch(newBatch, 250);

 *
 */
public with sharing class ForecastIsLevBatch implements Database.Batchable<sObject>{
    public final String QueryString;
    //private static String levementumAccountId = '001d000000JGuQaAAL';
    private static String levementumAccountName = 'Levementum LLC';
    private static String atgConsultantContactName = 'ATG Consultant';
    private static Date switchToATGTimeWeekEndDate = Date.newInstance(2022, 6, 4);
    
    public ForecastIsLevBatch() {
        System.debug('**** ForecastIsLevBatch ****');
            
        QueryString = 'SELECT Id, Name, Week_Start_Date__c, Week_End_Date__c, Deleted_in_Replicon__c, Project__c, Contact__c, Contact__r.Name, Contact__r.AccountId, Contact__r.Account.Name, Is_Lev_Forecast__c'
                            + ' FROM RepliconForecast__c'
                            + ' ORDER BY Project__c'; 
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('**** ForecastIsLevBatch START ****');
        return Database.getQueryLocator(QueryString);
    }

    public void execute(Database.BatchableContext BC, List<RepliconForecast__c> forecastList){
        System.debug('**** ForecastIsLevBatch EXECUTE ****');

        List<RepliconForecast__c> updateForecastList = new List<RepliconForecast__c>();
        for(RepliconForecast__c forecast : forecastList){
            /** 
             * Is Lev Forecast IF:
             *  Scenario 1: Forecast has  Week_End_Date__c Before or equal to 6/4/2022 AND is NOT related to ATG Consultant Contact
             *  Scenario 2: Forecast is After 6/4/2022 AND the Forecast's related Contact__c is associated with the Levementum LLC Account AND Contact__c is NOT ATG Consultant Contact
             */

            //Is Lev Forecast
            if(((forecast.Week_End_Date__c < switchToATGTimeWeekEndDate && forecast.Contact__r.Name != atgConsultantContactName) || (forecast.Week_End_Date__c >= switchToATGTimeWeekEndDate && forecast.Contact__r.Name != atgConsultantContactName && forecast.Contact__r.Account.Name == levementumAccountName)) && forecast.Is_Lev_Forecast__c != true){
                forecast.Is_Lev_Forecast__c = true;
                updateForecastList.add(forecast);

            //Is NOT Lev Forecast    
            }else if(forecast.Is_Lev_Forecast__c != false){
                forecast.Is_Lev_Forecast__c = false;
                updateForecastList.add(forecast);
            }
        }

        if(updateForecastList.size() > 0){
            update updateForecastList;
        }
        
    }

    public void finish(Database.BatchableContext BC){
        System.debug('**** ForecastIsLevBatch FINISH ****');

    }
}