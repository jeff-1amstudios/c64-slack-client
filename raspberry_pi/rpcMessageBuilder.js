const _ = require('lodash');
const logger = require('./logger');
const petscii = require('./petscii');
const MOCK_DATA = require('./_mockData');

const MOCK = false;
const C64_MAX_PAYLOAD_LENGTH = 1900;
const MAX_DMS = 15;
const MAX_CHANNELS = 15;

/*
*  struct {
*    byte totalPages,
*    byte pageSize,
*    channelData[] { byte len, char[] id, char[] name }
*/
function getChannelList(dataStore) {
  const pageIndex = 0;
  const buffer = Buffer.alloc((42 * MAX_CHANNELS) + 1);
  let offset = 0;

  let visibleChannels;
  let visibleGroups;
  if (MOCK) {
    visibleChannels = [];
    visibleGroups = MOCK_DATA.channels;
  } else {
    visibleChannels = _.filter(dataStore.channels, { is_member: true });
    visibleGroups = _.filter(dataStore.groups, { is_archived: false, is_mpim: false });
  }

  const channelsAndGroups = _.concat(visibleChannels, visibleGroups);
  const groups = _.orderBy(channelsAndGroups, ['unread_count_display', 'name'], ['desc', 'asc']);
  const page = _.slice(groups, pageIndex * MAX_CHANNELS, (pageIndex + 1) * MAX_CHANNELS);

  buffer.writeUInt8(Math.max(1, page.length / 19), offset++); // total pages
  buffer.writeUInt8(page.length, offset++);                   // page size

  _.each(page, (g) => {
    let entry = g.id;
    if (g.is_channel) entry += '#';
    entry += petscii.to(g.name.substring(0, 30));
    if (g.unread_count_display > 0) {
      entry += ` (${g.unread_count_display})`;
    }

    buffer.writeUInt8(entry.length, offset++);
    buffer.write(entry, offset, entry.length, 'ascii');
    offset += entry.length;
    if (offset >= C64_MAX_PAYLOAD_LENGTH) {
      logger.log('[ERROR]', 'Hit max payload length while building channel list');
      return false;
    }
    return true;
  });
  buffer.writeUInt8(0xff, offset++);
  return buffer.slice(0, offset);
}

function getDMList(dataStore) {
  const buffer = Buffer.alloc((42 * MAX_DMS) + 1);
  let offset = 0;
  let sortedDMs;
  if (MOCK) {
    sortedDMs = MOCK.dms;
  } else {
    sortedDMs = _.chain(dataStore.dms)
      .filter('latest')
      .orderBy(['unread_count_display', 'latest.ts'], ['desc', 'desc'])
      .take(MAX_DMS)
      .value();
  }

  const page = sortedDMs;
  buffer.writeUInt8(1, offset++);   // page count
  buffer.writeUInt8(page.length, offset++);

  _.forEach(page, (g) => {
    let entry = g.id;
    const username = MOCK ? 'mockuser' : dataStore.getUserById(g.user).name.substring(0, 30);
    entry += petscii.to(`@${username}`);
    if (g.unread_count_display > 0) {
      entry += `(${g.unread_count_display})`;
    }

    buffer.writeUInt8(entry.length, offset++);
    buffer.write(entry, offset, entry.length, 'ascii');
    offset += entry.length;
  });
  buffer.writeUInt8(0xff, offset++);

  // c64Channel.write('4', _.keys(page).length + ' dms, ' + offset + ' bytes...');
  return buffer.slice(0, offset);
}

function splitInto40CharacterLines(msg) {
  const lines = [];
  let lineStart = 0;
  let lineRun = 0;
  for (let i = 0; i < msg.length; i++) {
    if (msg[i] === '\r') {
      lines.push(msg.substring(lineStart, i));
      lineStart = i + 1;
      lineRun = 0;
    } else if (lineRun === 40) {
      lines.push(msg.substring(lineStart, i));
      lineStart = i;
      lineRun = 0;
    }
    lineRun++;
  }
  if (lineStart !== msg.length - 1) {
    const lastLine = _.trim(msg.substring(lineStart));
    if (lastLine.length > 0) {
      lines.push(msg.substring(lineStart));
    }
  }
  return lines;
}

function getMessageLines(msgBody) {
  const petsciiMsg = petscii.to(msgBody);
  return splitInto40CharacterLines(petsciiMsg);
}


module.exports = {
  getChannelList,
  getDMList,
  getMessageLines
};
