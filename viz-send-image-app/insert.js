var fs = require('fs');
var Cloudant = require('cloudant');
var configFile = require('./credentials.json');

if(!process.argv[2]) {
  console.log("Usage : node usage.js <filename>");
  return;
}

try {
    // Cloudant db credentials
    var cloudant = Cloudant({
      account : configFile.cloudantConfig.user,
      password : configFile.cloudantConfig.password
    });
    var imageDB = cloudant.db.use(configFile.cloudantConfig.dbName);

    fs.readFile(process.argv[2], function (err, data) {
        if (err) throw err;
        console.log(data);
        var time = Math.floor(new Date());
        console.log(time.toString());

        // Image insertion to Cloudant db
        imageDB.insert({
            "created"  : time,
            "payload"  : data,
            "typeId"   : configFile.iotconfig.typeId,
            "deviceId" : configFile.iotconfig.deviceId
          }, time.toString(), function (err, body) {
              if (!err)
                  console.log(body);
              else
                  console.log(err);
              });
    });
} catch (err) {
    console.log(err);
}
