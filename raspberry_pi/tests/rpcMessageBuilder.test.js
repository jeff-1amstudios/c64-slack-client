const assert = require('assert');
const rpcMessageBuilder = require('../rpcMessageBuilder');

describe('rpcMessageBuilder', () => {
  it('should not split short messages', () => {
    const lines = rpcMessageBuilder.getMessageLines('hello world');
    assert.equal(1, lines.length);
  });

  it('should split messages into lines of no more than 40 chars', () => {
    const lines = rpcMessageBuilder.getMessageLines('helloworldhello worldhello worldhello worldtrailingtext');
    assert.equal(2, lines.length);
  });

  it('should respect newlines in message', () => {
    const lines = rpcMessageBuilder.getMessageLines('hello\nworld');
    assert.equal(2, lines.length);
  });

  it('should not add empty lines', () => {
    const lines = rpcMessageBuilder.getMessageLines('helloworldhello world\n');
    assert.equal(1, lines.length);
  });
});
