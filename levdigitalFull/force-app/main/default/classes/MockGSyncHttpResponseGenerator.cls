/**
 * Created by jmahapatra on 3/12/18.
 */

@IsTest
global class MockGSyncHttpResponseGenerator implements HttpCalloutMock {

    global List<Object> responses = new List<Object>();
    global Integer responseIdx = 0;

    global MockGSyncHttpResponseGenerator() {

    }

    global MockGSyncHttpResponseGenerator(String body) {
        this.responses.add(body);
        this.responseIdx = 0;
    }

    global void add(Object body){
        this.responses.add(body);
    }

    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        system.debug(responses.size() + ' ' + responseIdx);
        Object body = responses[responseIdx];

        if(body instanceof String){
            res.setBody(String.valueOf(body));
        }else if(body instanceof Blob){
            res.setBodyAsBlob((Blob)body);
        }

        res.setStatus('OK');
        res.setStatusCode(200);
        return res;
    }
}