/**
 * Created by cmunoz on 10/5/18.
 */

global class GoogleDriveRestService {

    public static String errors = '';

    public static Blob getDriveFileContent(String fileId, Map<String, String> keyPair) {
        HttpRequest req = null;
        HttpResponse response = null;
        try {
            String access_token = keyPair.get('access_token');
            req = new HttpRequest();
            req.setEndpoint('https://www.googleapis.com/drive/v3/files/' + fileId + '?alt=media');
            req.setMethod('GET');

            req.setHeader('Authorization', 'Bearer ' + access_token);
            req.setHeader('Accept', 'application/json');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

            Http h = new Http();
            response = h.send(req);
        } catch(Exception ex) {
            Error_Log__c err = new Error_Log__c();
            err.Error__c = ex.getMessage() + '. ' + ex.getStackTraceString();
            err.File__c = 'GoogleDriveRestService';
            err.function__c = 'getDriveFileContent';
            err.Request__c = req != null ? req.toString() : '';
            err.Response__c = response != null ? response.toString() : '';
            err.Level__c = 'ERROR';
            errors += err.Error__c + '<br>';
            insert err;
        }
        return response != null ? response.getBodyAsBlob() : null;
    }

    public static void deleteFilefromGDrive(String fileId, String fileName, Map<String, String> keyPair) {
        HttpRequest req = null;
        HttpResponse response = null;
        try {
            String access_token = keyPair.get('access_token');
            req = new HttpRequest();
            req.setEndpoint('https://www.googleapis.com/drive/v2/files/' + fileId);
            req.setMethod('POST');
            req.setHeader('X-HTTP-Method-Override', 'PATCH');
            req.setHeader('Authorization', 'Bearer ' + access_token);
            req.setHeader('Content-Type', 'application/json');
            req.setBody('{"title":"Processed' + fileName.replace(' ', '') + '"}');
            Http h = new Http();
            response = h.send(req);
        } catch(Exception ex) {
            Error_Log__c err = new Error_Log__c();
            err.Error__c = ex.getMessage() + '. ' + ex.getStackTraceString();
            err.File__c = 'GoogleDriveRestService';
            err.function__c = 'deleteFilefromGDrive';
            err.Request__c = req != null ? req.toString() : '';
            err.Response__c = response != null ? response.toString() : '';
            err.Level__c = 'ERROR';
            errors += err.Error__c + '<br>';
            insert err;
        }
    }

    @TestVisible
    global static List<JsonObj> searchDrive(Map<String, String> keyPair) {
        HttpRequest req = null;
        HttpResponse response = null;
        List<JsonObj> listFiles = new List<JsonObj>();
        try {
            String access_token = keyPair.get('access_token');

            String root_folder = '';

            if (keyPair.containsKey('folder_id')) {
                root_folder = keyPair.get('folder_id');
            }
            System.debug('Root Folder: ' + root_folder);

            Datetime dt = System.now().addDays(-7);
            String GMTDate = dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');

            String q = '\'' + root_folder + '\' in parents and createdTime>=\'' + GMTDate + '\' and not name contains \'Processed\'' ;

            String searchString = EncodingUtil.urlEncode(q, 'UTF-8');
            req = new HttpRequest();
            req.setEndpoint('https://www.googleapis.com/drive/v3/files?q=' + searchString);
            req.setMethod('GET');

            req.setHeader('Authorization', 'Bearer ' + access_token);
            req.setHeader('Accept', 'application/json');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

            Http h = new Http();
            response = h.send(req);

            Map<String, Object> dMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

            List<Object> files = (List<Object>) dMap.get('files');
            if (files.size() > 0) {
                for (Integer i = 0; i < files.size(); i++) {
                    String js = JSON.serialize(files[i]);
                    JsonObj myobj = (JsonObj) JSON.deserialize(js, JsonObj.class);
                    listFiles.add(myobj);
                }
            }
            System.debug('listFiles' + listFiles);
        } catch(Exception ex) {
            Error_Log__c err = new Error_Log__c();
            err.Error__c = ex.getMessage() + '. ' + ex.getStackTraceString();
            err.File__c = 'GoogleDriveRestService';
            err.function__c = 'searchDrive';
            err.Request__c = req != null ? req.toString() : '';
            err.Response__c = response != null ? response.toString() : '';
            err.Level__c = 'ERROR';
            errors += err.Error__c + '<br>';
            insert err;
        }
        return listFiles;
    }

    @TestVisible
    global static Map<String, String> driveLogin() {
        HttpRequest req = null;
        HttpResponse response = null;
        Map<String, String> keyPair = new Map<String, String>();
        try {
            List<GooleDriveSync__mdt> keyVals = [SELECT DeveloperName,Value__c FROM GooleDriveSync__mdt];

            Map<String, String> KeyMaps = new Map<String, String>();
            if (keyVals.size() > 0) {
                for (GooleDriveSync__mdt obj : keyVals) {
                    KeyMaps.put(obj.DeveloperName, obj.Value__c);
                }
            }

            req = new HttpRequest();
            req.setEndpoint(KeyMaps.get('auth_url'));
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setBody('client_secret=' + KeyMaps.get('client_secret') + '&grant_type=refresh_token&refresh_token=' + KeyMaps.get('refresh_token') + '&client_id=' + KeyMaps.get('client_id') + '');

            Http h = new Http();
            response = h.send(req);
            Map<String, Object> dMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            System.debug('*resp1 ' + response.getBody());

            keyPair.put('access_token', String.valueOf(dMap.get('access_token')));
            keyPair.put('token_type', String.valueOf(dMap.get('token_type')));
            keyPair.put('email_id', KeyMaps.get('email_id'));
            keyPair.put('folder_id', KeyMaps.get('folder_id'));
        } catch(Exception ex) {
            system.debug(ex);
            Error_Log__c err = new Error_Log__c();
            err.Error__c = ex.getMessage() + '. ' + ex.getStackTraceString();
            err.File__c = 'GoogleDriveRestService';
            err.function__c = 'driveLogin';
            err.Request__c = req != null ? req.toString() : '';
            err.Response__c = response != null ? response.toString() : '';
            err.Level__c = 'ERROR';
            errors += err.Error__c + '<br>';
            insert err;
        }
        return keyPair;
    }

    global class JsonObj {
        public String id { get; set; }
        public String mimeType { get; set; }
        public String kind { get; set; }
        public String name { get; set; }
    }
}