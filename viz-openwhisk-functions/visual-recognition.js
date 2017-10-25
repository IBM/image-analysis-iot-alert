// Image processor code that will be sent to IoT Platform
var VisualRecognitionV3 = require('watson-developer-cloud/visual-recognition/v3');

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
        version_date: "2017-10-18"
    });

    var promise = new Promise(function(resolve, reject) {
        var params = {
          images_file: Buffer(data)
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
        });
      });
    return promise;
}
