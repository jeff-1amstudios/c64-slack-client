/*
 * Handles command stream from the C64 -> Raspberry Pi
 */

var events = require('events');

var _inputBuffer = '';
var lastFetched = 0;
var fetchingMessage = false;
var eventEmitter = new events.EventEmitter();

module.exports = {
  handle,
  eventEmitter
};


function handle(chunk) {
  _inputBuffer += chunk;
  if (!_inputBuffer.endsWith('~'))
    return;

  var cmd = _inputBuffer.substr(0, _inputBuffer.length - 1);
  console.error('recv', cmd);
  _inputBuffer = '';

  // heartbeat from c64
  if (cmd === 'hb') {
    if (!fetchingMessage && Date.now() - lastFetched > 1000) {
    }
  }
  else {
    eventEmitter.emit('gotCommandFromC64', cmd);
  }
}

