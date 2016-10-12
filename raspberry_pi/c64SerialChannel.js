const SerialPort = require('serialport');
const EventEmitter = require('events');

const MODE_STDOUT = 0;
const MODE_SERIAL_PORT = 1;

class C64SerialChannel extends EventEmitter {

  constructor() {
    super();
    this.inputBuffer = Buffer.alloc(0);
    this.lastFetched = 0;
    this.fetchingMessage = false;
  }

  useStandardOut() {
    this.mode = MODE_STDOUT;

    process.stdout.write('\x00');

    process.stdin.on('data', (data) => {
      if (data && data.length > 0) {
        this.handleInputFromC64(data);
      }
    });

    process.stdin.on('end', () => {
      process.exit(0);
    });
    process.stdin.on('close', () => {
      process.exit(0);
    });
    process.stdout.on('error', () => {
      process.stderr.write('stdout error');
    });
  }

  useRealSerialPort(name, baud) {
    this.mode = MODE_SERIAL_PORT;
    this.port = new SerialPort(name, {
      baudrate: baud
    });
    this.port.on('data', (data) => {
      if (data && data.length > 0) {
        this.handleInputFromC64(data);
      }
    });
  }

  write(commandId, payload) {
    console.error('writing', commandId, 'payload', payload);
    if (this.mode === MODE_SERIAL_PORT) {
      this.port.write(new Buffer([commandId]));
      this.port.write(payload);
      this.port.write('~');
    } else {
      process.stdout.write(new Buffer([commandId]));
      process.stdout.write(payload);
      process.stdout.write('~');
    }
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

    this.emit('commandReceived', cmd[0], cmd.slice(1));
  }
}

module.exports = C64SerialChannel;
