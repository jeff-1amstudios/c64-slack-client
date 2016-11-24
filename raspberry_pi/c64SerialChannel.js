const SerialPort = require('serialport');
const EventEmitter = require('events');
const logger = require('./logger');
const _ = require('lodash');

const MODE_STDOUT = 0;
const MODE_SERIAL_PORT = 1;
const COMMAND_TRAILING_CHAR = 0x7e;  // '~'

function getPrintableBytes(payload) {
  if (!payload) {
    return '';
  }

  let output = '';
  if (_.isString(payload)) {
    for (let i = 0; i < Math.min(40, payload.length); i++) {
      output += payload.charCodeAt(i).toString(16) + ' ';  // eslint-disable-line prefer-template
    }
    return output;
  }
  for (let i = 0; i < Math.min(40, payload.length); i++) {
    output += payload[i].toString(16) + ' ';  // eslint-disable-line prefer-template
  }
  return output;
}

class C64SerialChannel extends EventEmitter {

  constructor(serialPortDevice, baudrate) {
    super();
    this.inputBuffer = Buffer.alloc(0);
    this.lastFetched = 0;
    this.fetchingMessage = false;

    if (serialPortDevice) {
      this.useRealSerialPort(serialPortDevice, baudrate);
    } else {
      this.useStandardOut();
    }
  }

  useStandardOut() {
    logger.log('Using Vice64 serial port emulation');
    this.mode = MODE_STDOUT;

    process.stdout.write('\x00');

    process.stdin.on('data', (data) => {
      if (data && data.length > 0) {
        this.handleInputFromC64(data);
      }
    });

    process.stdin.on('end', () => {
      logger.log('Pi handler exiting');
      process.exit(0);
    });
    process.stdin.on('close', () => {
      logger.log('Pi handler exiting');
      process.exit(0);
    });
    process.stdout.on('error', (e) => {
      logger.log('stdout error', e);
    });
  }

  useRealSerialPort(name, baudrate) {
    logger.log('Using real serial port');
    this.mode = MODE_SERIAL_PORT;
    this.port = new SerialPort(name, {
      baudrate
    });
    this.port.on('data', (data) => {
      if (data && data.length > 0) {
        this.handleInputFromC64(data);
      }
    });
    this.port.on('open', () => {
      // for some reason the first byte is often corrupted, so send a dummy
      // rpc message before sending useful data
      const msg = [0, COMMAND_TRAILING_CHAR];
      this.port.write(Buffer.from(msg));
    });
  }

  write(commandId, payload) {
    logger.log(`[RPi >> C64] command=0x${commandId.toString(16)}, payload=${getPrintableBytes(payload)}`);
    const outputChannel = this.mode === MODE_SERIAL_PORT ? this.port : process.stdout;
    outputChannel.write(Buffer.from([commandId]));
    if (payload) {
      outputChannel.write(payload);
    }
    outputChannel.write(Buffer.from([COMMAND_TRAILING_CHAR]));
  }

  handleInputFromC64(chunk) {
    this.inputBuffer = Buffer.concat([this.inputBuffer, chunk]);
    // check for 'end-command' character
    if (this.inputBuffer[this.inputBuffer.length - 1] !== 0x7e) {
      return;
    }

    const cmd = Buffer.alloc(this.inputBuffer.length - 1);
    this.inputBuffer.copy(cmd, 0, 0, this.inputBuffer.length - 1);
    this.inputBuffer = Buffer.alloc(0);

    const commandId = cmd[0];
    const payload = cmd.slice(1);
    logger.log(`[C64 >> RPi] command=0x${commandId.toString(16)}, payload=${getPrintableBytes(payload)}`);
    this.emit('commandReceived', commandId, payload);
  }
}

module.exports = C64SerialChannel;
