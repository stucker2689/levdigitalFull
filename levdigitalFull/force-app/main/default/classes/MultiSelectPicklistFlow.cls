public with sharing class MultiSelectPicklistFlow {

    @InvocableMethod
    public static List<List<String>> CheckValues(List<String> values) {

        if(!(values.isEmpty())){
            String tempStr = values[0];
            List<String> ListNew = tempStr.split(';');
            List<List<String>> finalList = new List<List<String>>();
            finalList.add(ListNew);
            return finalList;
        }

        else return null;

    }
}