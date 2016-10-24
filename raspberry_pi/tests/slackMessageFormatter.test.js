const assert = require('assert');
const slackMessageFormatter = require('../slackMessageFormatter');

describe('slackMessageFormatter', () => {
  const mockDatastore = {
    getUserById: (id) => {
      const name = `user.from.store${id}`;
      return { name };
    }
  };

  it('should replace user tokens where the token contains pipe char', () => {
    const result = slackMessageFormatter.resolveTokens('hello <@UXXX|my.name> world', mockDatastore);
    assert.equal('hello @my.name world', result);
  });

  it('should replace user tokens where the token does not contain pipe char', () => {
    const result = slackMessageFormatter.resolveTokens('hello <@UXXX> world', mockDatastore);
    assert.equal('hello @user.from.storeUXXX world', result);
  });

  it('should replace unknown tokens where the token contains pipe char', () => {
    const result = slackMessageFormatter.resolveTokens('<foo|bar>', mockDatastore);
    assert.equal('bar', result);
  });

  it('should replace channel tokens where the token contains pipe char', () => {
    const result = slackMessageFormatter.resolveTokens('<#CXXX|my.channel>', mockDatastore);
    assert.equal('#my.channel', result);
  });
});
