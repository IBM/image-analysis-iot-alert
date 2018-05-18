// Image processor code that will be sent to IoT Platform
var VisualRecognitionV3 = require('watson-developer-cloud/visual-recognition/v3');
var fs = require('fs');
var os = require('os');
var path = require('path');
var uuid = require('uuid');

function main(params) {
    // params coming from Cloudant
    var data = params.payload;
    var typeId = params.typeId;
    var deviceId = params.deviceId;
    var docId = params._id;

    var classifiers = params.classifiers;
    var apiKey = params.apikey;

    if(!apiKey) {
        return Promise.reject('apiKey for the Watson Visual Recognition is required.');
    }

    // Visual recognition api key from config file
    var visual_recognition = new VisualRecognitionV3({
      api_key: apiKey,
      version_date: "2018-03-19"
    });

    var promise = new Promise(function(resolve, reject) {
        var temp = path.join(os.tmpdir(), uuid.v1() + '.tmp');
        fs.writeFileSync(temp, new Buffer(data, 'base64'));
        var params = {
          images_file: fs.createReadStream(temp)
        };

        if(classifiers) {
          params.classifier_ids = classifiers;
        }

        // Classifiers will be set to a device in the IoT Platform
        visual_recognition.classify(params, function(err, res) {
          if (err) {
            console.log(err);
            reject(err);
          } else {
            console.log(JSON.stringify(res, null, 2));
            resolve({payload : res, docId : docId, typeId : typeId, deviceId : deviceId});
          }
          fs.unlink(params.images_file.path, function(e) {
            if (e) {
              console.log('Error deleting temp image file %s: %s', params.images_file.path, e);
            }
          });
        });
      });
    return promise;
}
