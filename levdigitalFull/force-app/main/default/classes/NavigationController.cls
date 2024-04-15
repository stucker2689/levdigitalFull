/**
 * Created by jmahapatra on 2/26/18.
 */

public with sharing class NavigationController {

    public class Nav{
        @AuraEnabled
        public String Label{set;get;}

        @AuraEnabled
        public String Url{set;get;}
    }

    @AuraEnabled
    public static List<Nav> getUrls()
    {
        List<Nav> navs = new List<Nav>();
        String userId = UserInfo.getUserId();
        DateTime d = Date.Today() ;
        String dateStr =  d.format('MM/dd/yyyy') ;

        List<CustomNavigation__mdt> urls = [select Label,Link__c from CustomNavigation__mdt];
        for (CustomNavigation__mdt url:urls){
            String lbl = url.Label;
            String link = url.Link__c;

            if(lbl.equalsIgnoreCase('generate booked not billed report')){
                link = link.replace('{!$User.Id}',userId);
                link = link.replace('{!TODAY()}',dateStr);
            }
            Nav obj = new Nav();
            obj.Label = lbl;
            obj.Url = link;

            navs.add(obj);
        }
        return navs;
    }
}