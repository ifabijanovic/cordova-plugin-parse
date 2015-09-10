var exec = require('cordova/exec');
var callbackMap = {};
var noop = function(){};

exports.notificationType = {
    none: 0,
    badge: 1,
    sound: 2,
    alert: 4
};

exports.notificationEventType = {
    registration: 'registration',
    push: 'push'
};

exports.initialize = function(applicationId, clientKey, success, error) {
    exec(success, error, "cordova-parse-push", "initialize", [applicationId, clientKey]);
};

exports.registerForNotificationTypes = function(types, success, error) {
    exec(success, error, "cordova-parse-push", "registerForNotificationTypes", [types]);
};

exports.registerEvent = function(type, callback) {
    callbackMap[type] = callback;
};

exports.getLaunchNotification = function(callback) {
    exec(callback, noop, "cordova-parse-push", "getLaunchNotification", []);
};

exports.setBadgeNumber = function(value) {
    exec(noop, noop, "cordova-parse-push", "setBadgeNumber", [value]);
};

exports.setAlias = function(value) {
    exec(noop, noop, "cordova-parse-push", "setAlias", [value]);
};

exports.getChannels = function(success, error) {
    exec(success, error, "cordova-parse-push", "getChannels", []);
};

exports.setChannels = function(channels, success, error) {
    exec(success, error, "cordova-parse-push", "setChannels", [channels]);
};

exports.raiseEvent = function(type, data) {
    if (callbackMap[type]) {
        callbackMap[type](data);
    }
};
