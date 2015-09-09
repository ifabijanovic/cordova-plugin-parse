var exec = require('cordova/exec');

exports.notificationType = {
    none: 0,
    badge: 1,
    sound: 2,
    alert: 4
};

exports.initialize = function(applicationId, clientKey, success, error) {
    exec(success, error, "cordova-parse-push", "initialize", [applicationId, clientKey]);
};

exports.registerForNotificationTypes = function(types, success, error) {
    exec(success, error, "cordova-parse-push", "registerForNotificationTypes", [types]);
};