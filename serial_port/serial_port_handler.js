#!/usr/bin/env node
'use strict';
var Promise = require('bluebird');
var _ = require('lodash');
var fs = require('fs');
var util = require('util');

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
      consoleLog('Slack: ' + level + ',' + str);
    }
  }
});
rtm.start();

rtm.on(RTM_EVENTS.MESSAGE, function (message) {
  if (message.channel === selectedChannel) {
    writeMessage(message);
  }
});

var lastUserId = '';

function writeMessage(message) {
  if (message.hidden === true) {
    return;
  }

  var msg = '';
  if (lastUserId !== message.user) {
    var user = rtm.dataStore.getUserById(message.user);
    var msgDate = new Date(parseFloat(message.ts) * 1000);
    var headerText = util.format('%s %d:%d ', user.profile.real_name.substring(0, 32), msgDate.getHours(), msgDate.getMinutes());
    var paddingLength = (40 - headerText.length);
    headerText = headerText + _.repeat(String.fromCharCode(0xc0), paddingLength);
    lastUserId = message.user;
    write('1 ');
    write('3' + toPetscii(headerText));
  }
  msg += message.text.substring(0, 255);
  var lines = getMessageLines(msg);
  for (let line of lines) {
    write('1' + toPetscii(line))
  }
}

function getMessageLines(msg) {
  var lines = [];
  var lineStart = 0;
  var lineRun = 0;
  for (var i = 0; i < msg.length; i++) {
    if (msg[i] === '\n') {
      lines.push(msg.substring(lineStart, i));
      lineStart = i+1;
      lineRun = 0;
    }
    else if (lineRun === 40) {
      lines.push(msg.substring(lineStart, i));
      lineStart = i;
      lineRun = 0; 
    }
    lineRun++;
  }
  if (lineStart != msg.length -1) {
    lines.push(msg.substring(lineStart));
  }
  
  return lines;
}


 rtm.on(CLIENT_EVENTS.RTM.AUTHENTICATED, (rtmStartData) => {
  consoleLog('connected');

  write('2' + toPetscii(rtmStartData.self.name));
 });


var mode = 0; // 0 = stdin/out, 1 = serial

const CHANNEL_LIST_REQUEST = 0x30;
const CHANNEL_LIST_RESPONSE = 0x30;
const CHANNEL_SELECT_REQUEST = 0x31;
const MSG_REQUEST = 0x31;
const HELLO_REQUEST = 0x32;


commandHandler.eventEmitter.on('gotCommandFromC64', (data) => {
  if (data[0] === CHANNEL_LIST_REQUEST) {
    var page = data[1];
    var output = getChannels(page);
    fs.writeFile('/tmp/channels', output);
    write(output);
  }
  else if (data[0] === CHANNEL_SELECT_REQUEST) {
    //consoleLog('req', data);
    selectedChannel = data.slice(1).toString('utf-8');
    consoleLog('channel select', selectedChannel);

    var historyFn;
    if (selectedChannel[0] === 'C') {
      historyFn = web.channels;  
    }
    else {
      historyFn = web.groups;  
    }

    historyFn.history(selectedChannel, {
      count: 20
    })
      .then((res) => {
        _.forEachRight(res.messages, (m) => {
          writeMessage(m);
        });
      });
  }
  else {
    consoleLog('unknown command:', data);
  }
});


function write(buffer) {
  consoleLog('writing len=', buffer.length, buffer);
//  consoleLog('writing:' + buffer.toString());
  if (mode === 1) {
      port.write(buffer);
      port.write('~');
  }
  else {
    process.stdout.write(buffer);
    process.stdout.write('~');
  }
}


// from petcat.c
function toPetscii(input) {
  input = input.replace(/\n/g, "@@@");
  input = input.replace(/_/g, '-');
  input = input.replace(/`/g, '\"');
  input = input.replace(/[^A-Za-z 0-9 \.,\?""!@#\$%\^&\*\(\)-_=\+;:<>\/\\\|\}\{\[\]`~]*/g, '');
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

  process.stdin.on('data', (data) => {
    if (data && data.length > 0) {
      commandHandler.handle(data);
    }
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
    consoleLog('port opened');
  });
  port.on('data', function(data) {
    if (data && data.length > 0) {
      commandHandler.handle(data);
    }
  });
}

/*
*  struct {
*    byte msgid,
*    byte totalPages,
*    byte pageSize,
*    channelData[] { byte len, char[] id, char[] name }
*/
function getChannels(page) {
  const PAGE_SIZE = 15;
  var buffer = Buffer.alloc(1000);
  var offset = 0;
  //var channelsAndGroups = {};
  var visibleChannels = _.filter(rtm.dataStore.channels, {is_member: true});
  var visibleGroups = _.filter(rtm.dataStore.groups, (g) => !g.is_archived && !g.is_mpim);

  // var visibleGroups = [{
  //   name: 'test1',
  //   id: 'G24Q7DAD8'
  // },
  // {
  //   name: 'test2',
  //   id: 'G24Q7DAD8'
  // },
  // {
  //   name: 'test3',
  //   id: 'G24Q7DAD8'
  // },
  // {
  //   name: 'test4',
  //   id: 'G24Q7DAD8'
  // },
  // {
  //   name: 'test5',
  //   id: 'G24Q7DAD8'
  // },
  // {
  //   name: 'test6',
  //   id: 'G24Q7DAD8'
  // }];
  // var visibleChannels = [];
  var channelsAndGroups = _.concat(visibleChannels, visibleGroups);
  var groups = _.sortBy(channelsAndGroups, 'name');
  var page = _.slice(groups, page * PAGE_SIZE, (page + 1) * PAGE_SIZE);

  buffer.writeUInt8(CHANNEL_LIST_RESPONSE, offset++);
  buffer.writeUInt8(groups.length / PAGE_SIZE, offset++);
  buffer.writeUInt8(page.length, offset++);

  var output = '';
  var count = 0;
  _.each(page, (g) => {
    var entry = g.id;
    if (g.is_channel) entry += '#';
    entry += toPetscii(g.name.substring(0, 30));
    if (g.unread_count_display > 0) {
      entry += ' (' + g.unread_count_display + ')';
    }

    buffer.writeUInt8(entry.length, offset++);
    buffer.write(entry, offset, entry.length, 'ascii');
    offset += entry.length;
    count++;
  });

  if (offset > 1200) {
    consoleLog('[ERROR] ** channels output too long! **');
  }
  var finalBuffer = Buffer.alloc(offset);
  buffer.copy(finalBuffer, 0, 0, offset);
  return finalBuffer;
}

getChannels(0)
//  .then((c) => console.error(c));


// web.groups.history('G02H6KDMJ', { count: 20, unreads: 1}, (err, res) => {
//   console.log(res);
// });

function consoleLog() {
  // write debug messages to stderr as stdout is read by c64 emulator
  console.error(arguments);
}

// countMessageLines('-- Dan Diephouse 8:32 --\n
// CloudHub Worker Cloud Degradation in US-East ?')

//write('2Jeff Harris~');