# Slack client for Commodore 64

<img src="_assets/readme-img.jpg" />
_Where a Raspberry Pi and a Commodore64 collaborate with Slack._

## Commodore 64 program
The c64 program code is written in [6502 assembly](https://en.wikipedia.org/wiki/MOS_Technology_6502) and somewhat(?!) well documented. 

### Compiling
Grab dependency: [ACME assembler](https://sourceforge.net/projects/acme-crossass/)
```
cd c64
acme main.asm
```
This will create `build/slack-client.prg`.

### Running the program on real hardware
If you are reading this, have a C64, and plan to run this program on it, you likely don't need step-by-step instructions ;). Obviously it will
need to copied onto a floppy disk, disk emulator etc.
```
LOAD "SLACK-CLIENT.PRG",<device_nbr>
RUN
```

### Running with the [Vice64](http://vice-emu.sourceforge.net/) emulator
First, we need to configure the emulated serial port.

Open 'Settings' > 'Resource Inspector' window
```
Peripherals > Cartridges > Userport RS232 > 
  Baud Rate: 1200, 
  Enabled: true, 
  Device: device4
RS232 > Device4 > 
  Device: |../raspberry_pi/app.js, 
  Baud Rate: 1200
```
Hit 'Save current settings', then Quit.

```
/path/to/x64 build/x64 c64/build/slack-client.prg
```

## Raspberry Pi Slack API proxy
This is a NodeJS app which connects to the Slack RTM api on one side, and a serial port connection to the C64 on the other side and translates 
data back and forth.

It can be configured to communicate via a real serial port, or via stdout/stdin (for Vice64 emulator)

### Configuration
First, you need to create a Slack OAuth token here https://api.slack.com/docs/oauth-test-tokens

```
export SLACK_API_TOKEN=token
```

If `C64_SLACK_SERIALPORT_DEVICE` is not defined, it will use stdout/stdin for communication. To communicate via a real serial port:
```
export C64_SLACK_SERIALPORT_DEVICE=/dev/ttyUSB0 (or /dev/cu.usbserial etc)
```

Run the API proxy:
```
cd raspberry_pi
npm install
node app.js
```
On startup, it will authenticate with Slack RTM api, then send a `HELLO` RPC message to the C64, which we expect to already be running.


### Helpful links
- 6502 opcodes reference - http://www.6502.org/tutorials/6502opcodes.html
- Official Commodore 64 Programmer's Reference Guide - http://www.zimmers.net/cbmpics/cbm/c64/c64prg.txt
- Intro to C64 programming - http://dustlayer.com/tutorials/


### ISC License
Copyright (c) 2016, Jeffrey Harris

Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
