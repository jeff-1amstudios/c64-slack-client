#!/usr/bin/env node
'use strict';
var Promise = require('bluebird');
var _ = require('lodash');
var commandHandler = require('./c64CommandListener.js');
var SerialPort = require("serialport");

var WebClient = require('@slack/client').WebClient;
var token = process.env.SLACK_API_TOKEN || '';
var web = new WebClient(token);

var mode = 0; // 0 = stdin/out, 1 = serial

console.error('loaded');

const CHANNEL_RESPONSE = '0';


commandHandler.eventEmitter.on('gotCommandFromC64', (data) => {
  if (data === 'channels.list') {
    return Promise.resolve() // getChannels()
      .then((c) => write(CHANNEL_RESPONSE + '\x06' + ':g20upec1l:3-8-1-release:g19jr8hps:alerts-quota:g06fxewts:amc-product-and-leads:g20upec1l:3-8-1-release:g19jr8hps:alerts-quota:g06fxewts:amc-product-and-leads'));
  }
  else {
    write('got data');
  }
});


function write(str) {
  var str = str[0] + convertToPetscii(str.substring(1));
  str += '~';  // add end marker
  process.stderr.write("writing " + str + "\n");
  if (mode === 1) {
      port.write(str, function(e, bytesWritten) {
        if (e) {
          console.error('error', e);
        }
      });
  }
  else {
    process.stdout.write(str);
  }
}


// from petcat.c
function convertToPetscii(input) {
  input = input.replace(/\n/g, "@@@");
  var output = '';
  for (var i = 0; i < input.length; i++) {
    var ascii = input.charCodeAt(i);
    if (ascii >= 65 && ascii <= 90) {
      output += String.fromCharCode(ascii + 32);
    }
    else if (ascii >= 97 && ascii <= 122) {
      output += String.fromCharCode(ascii - 32);
    }
    else {
      output += input[i];
    }
  }
  output = output.replace(/@@@/g, "\x0d");
  return output;
}


if (mode === 0) {
  // seems to be needed to 'wake up' the connection
  process.stdout.write('\x00');

  process.stdin.on('data', (chunk) => {
//    console.error(chunk);
    var chars = chunk.toString('utf-8');
//    console.error(chars);
    commandHandler.handle(chars);
  });

  process.stdin.on('end', function () {
    process.exit(0);
  });
  process.stdin.on('close', function () {
    process.exit(0);
  });
  process.stdout.on('error', function () {
    process.stderr.write('stdout error');
  });
}
else {
  var port = new SerialPort("/dev/ttyUSB0", {
    baudrate: 1200
  });
  port.on('open', function () {
    console.error('port opened');
  });
  port.on('data', function(data) {
    if (data && data.length > 0) {
      commandHandler.handle(data.toString());
    }
  });
}

// id:name[0-40]
function getChannels() {
  return web.groups.list({ exclude_archived: true })
    .then((res) => {
      var output = '';
      _.each(res.groups, (g) => {
        if (g.is_mpim) {
          return;
        }
        output += g.id + ':' + g.name.substring(0, 40) + ':';
      });
      return output;
    });
}

//getChannels()
//  .then((c) => console.error(c));


// web.groups.history('G02H6KDMJ', { count: 20, unreads: 1}, (err, res) => {
//   console.log(res);
// });
