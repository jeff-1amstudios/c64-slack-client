#!/usr/bin/env node
'use strict';
var Promise = require('bluebird');
var _ = require('lodash');
var fs = require('fs');

var commandHandler = require('./c64CommandListener.js');
var SerialPort = require("serialport");

var WebClient = require('@slack/client').WebClient;
var RtmClient = require('@slack/client').RtmClient;
var MemoryDataStore = require('@slack/client').MemoryDataStore;

var CLIENT_EVENTS = require('@slack/client').CLIENT_EVENTS;
var RTM_EVENTS = require('@slack/client').RTM_EVENTS;

var token = process.env.SLACK_API_TOKEN || '';
var selectedChannel = '';

var web = new WebClient(token);
var rtm = new RtmClient(token, {
  dataStore: new MemoryDataStore(),
  logLevel: 'error',
  logger: function(level, str) {
    if (level === 'error') {
      console.error('Slack:', level, str);
    }
  }
});
rtm.start();

rtm.on(RTM_EVENTS.MESSAGE, function (message) {
  console.error(message);
  if (message.channel === selectedChannel) {
    writeMessage(message);
  }
});

function writeMessage(message) {
  var user = rtm.dataStore.getUserById(message.user);
  var msg = toPetscii('-- ' + user.profile.real_name + ' --\n' + message.text + '\n\n');
  write(MSG_REQUEST + msg + '~');
}


 rtm.on(CLIENT_EVENTS.RTM.AUTHENTICATED, function (rtmStartData) {
  var r= rtm;
  debugger;
//   //groups = _.filter(rtmStartData.groups, { is_archived: false});
//   //console.error(rtmStartData);
//   //console.log(`Logged in as ${rtmStartData.self.name} of team ${rtmStartData.team.name}, but not yet connected to a channel`);
 });


var mode = 0; // 0 = stdin/out, 1 = serial

console.error('loaded');

const CHANNEL_LIST_REQUEST = '0';
const CHANNEL_LIST_RESPONSE = '0';
const CHANNEL_SELECT_REQUEST = '1';
const MSG_REQUEST = '1';


commandHandler.eventEmitter.on('gotCommandFromC64', (data) => {
  if (data === CHANNEL_LIST_REQUEST) {
    return getChannels()
      .then((c) => {
        fs.writeFile('/tmp/channels', c);
        return c;
      })
      .then((c) => write(c));
  }
  else if (data[0] === CHANNEL_SELECT_REQUEST) {
    selectedChannel = data.substring(1);
    var channel = rtm.dataStore.getGroupById(selectedChannel);
    console.error(selectedChannel, channel);
    if (channel && channel.latest) {
      writeMessage(channel.latest);
    }
    console.error('channel select', selectedChannel);
  }
  else {
    console.error('unknown command:', data);
  }
});


function write(buffer) {
  //console.error('writing:', buffer, 'str:', buffer.toString());
  console.error('writing:', buffer.toString());
  if (mode === 1) {
      port.write(buffer, function(e, bytesWritten) {
        if (e) {
          console.error('error', e);
        }
      });
  }
  else {
    process.stdout.write(buffer);
  }
}


// from petcat.c
function toPetscii(input) {
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
    var chars = chunk.toString('utf-8');
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

/*
*  struct {
*    byte type, 
*    byte entryCount
*    short[] entryOffsets
*    ... entryData (id,name)...
*/
function getChannels() {
  return web.groups.list({ exclude_archived: true })
    .then((res) => {
      if (res.groups.length > 10) {
        res.groups.length = 10;
      }
      var entryOffsetsTableLength = res.groups.length * 2;

      var buffer = Buffer.alloc(1000);
      var offset = 0;
      buffer.write(CHANNEL_LIST_RESPONSE, offset++);
      buffer.writeUInt8(res.groups.length, offset++);

      var output = '';
      var entryLengths = [];
      _.each(res.groups, (g) => {
        if (g.is_mpim) {
          return;
        }        
        
        var entry = g.id + g.name.substring(0, 40);
        //console.error('entry:', entry);
        buffer.writeUInt8(entry.length, offset++);
        buffer.write(entry, offset);
        offset += entry.length;
      });

      buffer.write('~', offset++);

      if (offset > 250) {
        console.error("output too long!");
      }
      var finalBuffer = Buffer.alloc(offset);
      buffer.copy(finalBuffer, 0, 0, offset);
      return finalBuffer;
    });
}

//getChannels()
//  .then((c) => console.error(c));


// web.groups.history('G02H6KDMJ', { count: 20, unreads: 1}, (err, res) => {
//   console.log(res);
// });
