var exec = require('cordova/exec');

exports.initialize = function(applicationId, clientKey, success, error) {
    exec(success, error, "cordova-plugin-parse", "initialize", [applicationId, clientKey]);
};

exports.registerForNotificationTypes = function(types, success, error) {
    exec(success, error, "cordova-plugin-parse", "registerForNotificationTypes", [types]);
};
