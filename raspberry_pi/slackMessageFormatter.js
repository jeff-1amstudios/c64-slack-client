// https://api.slack.com/docs/message-formatting#how_to_display_formatted_messages

const _ = require('lodash');

const tokenRegex = /<(.*?)>/g;

function resolveTokens(msg, slackDataStore) {
  const formattedMsg = msg.replace(tokenRegex, (match, matchGroup) => {
    if (_.startsWith(matchGroup, '@U')) {
      if (matchGroup.indexOf('|') !== -1) {
        return `@${matchGroup.substring(matchGroup.indexOf('|') + 1)}`;
      }
      return `@${slackDataStore.getUserById(matchGroup.substring(1)).name}`;
    } else if (_.startsWith(matchGroup, '#C')) {
      if (matchGroup.indexOf('|') !== -1) {
        return `#${matchGroup.substring(matchGroup.indexOf('|') + 1)}`;
      }
    } else if (matchGroup.indexOf('|') !== -1) {
      return matchGroup.substring(matchGroup.indexOf('|') + 1);
    }
    return matchGroup;
  });

  return formattedMsg;
}

module.exports = {
  resolveTokens
};
