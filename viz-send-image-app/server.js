var Express = require('express');
var multer = require('multer');
var bodyParser = require('body-parser');
var fs = require('fs');
var app = Express();
var path = require("path");
var Cloudant = require('cloudant');
var configFile = require('./credentials.json');

app.use(bodyParser.json());

var Storage = multer.diskStorage({
    destination: function (req, file, callback) {
        callback(null, "./images");
    },
    filename: function (req, file, callback) {
        callback(null, file.fieldname + "_" + Date.now() + "_" + file.originalname);
    }
});

var upload = multer({ storage: Storage }).array("imgUploader", 3);

var cloudant = Cloudant({
  account : configFile.cloudantConfig.user,
  password : configFile.cloudantConfig.password
});
var imageDB = cloudant.db.use(configFile.cloudantConfig.dbName);

app.get("/", function (req, res) {
    res.sendFile(__dirname + "/index.html");
});

app.post("/api/Upload", function (req, res) {
    upload(req, res, function (err) {
        if (err) {
            return res.end("Something went wrong!");
        }
        var fileInfo = JSON.parse(JSON.stringify(req.files));
        for(var i=0; i<fileInfo.length; i++){
          var count = fileInfo[i];
          insertToCloudant(count.path, count.filename);
        }

			return res.end("File uploaded sucessfully!.")
    });

});

function insertToCloudant(source, target) {
  try {
      fs.readFile(source, function (err, data) {
          if (err) throw err;
          console.log(data);
          var time = Math.floor(new Date());
          console.log(time.toString());

          imageDB.insert({
              "created"  : time,
              "payload"  : data,
              "typeId"   : configFile.iotconfig.typeId,
              "deviceId" : configFile.iotconfig.deviceId
            }, time.toString(), function (err, body) {
                if (!err){
                  console.log('body: ' + body);
                }
                else {
                    console.log('error: ' + err);
                }
                });
        });
      } catch (err) {
        console.log(err);
      }
}

app.listen(3000, function (a) {
    console.log("Listening to port 3000");
});
