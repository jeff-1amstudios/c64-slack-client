#!/usr/bin/env node

const _ = require('lodash');
const util = require('util');

const WebClient = require('@slack/client').WebClient;
const RtmClient = require('@slack/client').RtmClient;
const MemoryDataStore = require('@slack/client').MemoryDataStore;
const CLIENT_EVENTS = require('@slack/client').CLIENT_EVENTS;
const RTM_EVENTS = require('@slack/client').RTM_EVENTS;

const logger = require('./logger');
const slackMessageFormatter = require('./slackMessageFormatter');
const C64SerialChannel = require('./c64SerialChannel');
const petscii = require('./petscii');
const rpcMessageBuilder = require('./rpcMessageBuilder');
const rpcMethods = require('./rpcMethods');

const token = process.env.SLACK_API_TOKEN || '';

const web = new WebClient(token);
const rtm = new RtmClient(token, {
  dataStore: new MemoryDataStore(),
  logLevel: 'error',
  logger: function slackLogger(level, str) {
    if (level === 'error') {
      logger.log('Slack:', level, str);
    }
  }
});

const clientContext = {
  selectedChannelId: null,
  lastUserId: null
};

const c64Channel = new C64SerialChannel();
c64Channel.useStandardOut();

// Converts a slack message into a set of lines and sends each one across the C64 channel
function writeSlackMessageToC64(message) {
  if (message.hidden) {
    return;
  }

  if (clientContext.lastMessageUserId !== message.user) {
    const user = rtm.dataStore.getUserById(message.user);
    const msgDate = new Date(parseFloat(message.ts) * 1000);
    let headerText = util.format('%s %d:%d ', user.profile.real_name.substring(0, 32), msgDate.getHours(), msgDate.getMinutes());
    const paddingLength = (40 - headerText.length);
    headerText += _.repeat(String.fromCharCode(0xc0), paddingLength);
    clientContext.lastMessageUserId = message.user;
    c64Channel.write(rpcMethods.MSG_LINE, ' ');
    c64Channel.write(rpcMethods.MSG_HEADER_LINE, petscii.to(headerText));
  }

  const msgBody = slackMessageFormatter.formatSlackTokens(
    message.text.substring(0, 255),
    rtm.dataStore);

  _.each(rpcMessageBuilder.getMessageLines(msgBody), (payload) => {
    c64Channel.write(rpcMethods.MSG_LINE, payload);
  });
}

c64Channel.on('commandReceived', (command, data) => {
  logger.log('commandReceived', command);

  switch (command) {
    case rpcMethods.CHANNEL_LIST: {
      const output = rpcMessageBuilder.getChannelList(rtm.dataStore);
      c64Channel.write(rpcMethods.CHANNELS_INFO, `${output[1]} channels, ${output.length} bytes...`);
      c64Channel.write(rpcMethods.CHANNEL_LIST, output);
      break;
    }
    case rpcMethods.DMS_LIST: {
      const output = rpcMessageBuilder.getDMList(rtm.dataStore);
      c64Channel.write(rpcMethods.DMS_LIST, output);
      break;
    }
    case rpcMethods.CHANNEL_SELECT: {
      clientContext.selectedChannelId = data.toString('ascii');
      clientContext.lastMessageUserId = null;
      logger.log('channel-select', clientContext.selectedChannelId);

      let channelType;
      if (clientContext.selectedChannelId[0] === 'C') {
        channelType = web.channels;
      } else if (clientContext.selectedChannelId[0] === 'G') {
        channelType = web.groups;
      } else if (clientContext.selectedChannelId[0] === 'D') {
        channelType = web.im;
      }

      channelType.history(clientContext.selectedChannelId, {
        count: 5
      })
        .then((res) => {
          _.forEachRight(res.messages, (m) => {
            writeSlackMessageToC64(m);
          });
        });
      break;
    }
    case rpcMethods.SEND_MESSAGE: {
      const msgBody = petscii.from(data.toString('ascii'));
      rtm.sendMessage(msgBody, clientContext.selectedChannelId)
        .then((sentMessage) => {
          writeSlackMessageToC64(sentMessage);
        });
      break;
    }

    default: {
      logger.log('unknown command:', data);
    }

  }
});

logger.log('Waiting for Slack RTM connection...');
rtm.start();

rtm.on(CLIENT_EVENTS.RTM.AUTHENTICATED, (rtmStartData) => {
  logger.log('Slack RTM client connected');
  c64Channel.write(rpcMethods.HELLO, petscii.to(rtmStartData.self.name.substring(0, 20)));
});

rtm.on(RTM_EVENTS.MESSAGE, (message) => {
  // hack - slack client doesn't seem to update the `latest` property
  if (message.channel[0] === 'D') {
    rtm.dataStore.getDMById(message.channel).latest = message;
  }
  // if we get a message on the listening channel, send it
  if (message.channel === clientContext.selectedChannelId) {
    writeSlackMessageToC64(message);
  }
});