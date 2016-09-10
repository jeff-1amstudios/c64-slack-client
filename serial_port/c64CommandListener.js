/*
 * Handles command stream from the C64 -> Raspberry Pi
 */

var events = require('events');

var _inputBuffer = Buffer.alloc(0);
var lastFetched = 0;
var fetchingMessage = false;
var eventEmitter = new events.EventEmitter();

module.exports = {
  handle,
  eventEmitter
};


function handle(chunk) {
  _inputBuffer = Buffer.concat([_inputBuffer, chunk]);
  //console.error('chunk_str', _inputBuffer);
  if (_inputBuffer[_inputBuffer.length-1] !== 0x7e) {
    return;
  }

  var cmd = Buffer.alloc(_inputBuffer.length - 1); // _inputBuffer.substr(0, _inputBuffer.length - 1);
  _inputBuffer.copy(cmd, 0, 0, _inputBuffer.length - 1);
  //console.error('got chunk:', cmd);
  _inputBuffer = Buffer.alloc(0);

  // heartbeat from c64
  if (cmd === 'hb') {
    if (!fetchingMessage && Date.now() - lastFetched > 1000) {
    }
  }
  else {
    eventEmitter.emit('gotCommandFromC64', cmd);
  }
}

