function Flashlight() {
  // track flashlight state
  this._isSwitchedOn = false;
}

Flashlight.prototype = {

  available: function (callback) {
    cordova.exec(function (avail) {
      callback(avail ? true : false);
    }, null, "Flashlight", "available", []);
  },

  switchOn: function (successCallback, errorCallback) {
    this._isSwitchedOn = true;
    cordova.exec(successCallback, errorCallback, "Flashlight", "switchOn", []);
  },

  switchOff: function (successCallback, errorCallback) {
    this._isSwitchedOn = false;
    cordova.exec(successCallback, errorCallback, "Flashlight", "switchOff", []);
  },

  sendData: function (successCallback, errorCallback, c, bits, pulse_width_ms) {
    cordova.exec(successCallback, errorCallback, "Flashlight", "sendData", [c, bits, pulse_width_ms]);
  },

  toggle: function (successCallback, errorCallback) {
    if (this._isSwitchedOn) {
      this.switchOff(successCallback, errorCallback);
    } else {
      this.switchOn(successCallback, errorCallback);
    }
  }
};

Flashlight.install = function () {
  if (!window.plugins) {
    window.plugins = {};
  }

  window.plugins.flashlight = new Flashlight();
  return window.plugins.flashlight;
};

cordova.addConstructor(Flashlight.install);