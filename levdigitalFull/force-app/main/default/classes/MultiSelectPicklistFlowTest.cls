@isTest
public class MultiSelectPicklistFlowTest{   

    @isTest
    static void MultiSelectFlowValuesTest(){    

        List<String> tempList = new list<String>();
        tempList.add('Audience Studio;Campaign Services;Interaction Studio;CDP;Marketing Cloud');
        List<List<String>> testResult = MultiSelectPicklistFlow.CheckValues(tempList);
        List<String> resultList = testResult[0];
        System.assertEquals(5, resultList.size(), 'Returned List was not the expected Size');
        System.assertEquals(true, resultList.contains('Audience Studio'), 'List did not contain Expected String');
    }

    @isTest
    static void MultiSelectFlowValuesNullTest(){    

        List<String> tempNullList = new List<String>();
        List<List<String>> testNullResult = MultiSelectPicklistFlow.CheckValues(tempNullList);
        System.debug(testNullResult);
        System.assertEquals(null, testNullResult, 'Null Parameters did not return Null response');
    }

}