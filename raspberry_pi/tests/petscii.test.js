const assert = require('assert');
const petscii = require('../petscii');

describe('petscii', () => {
  it('should convert from ascii to petscii', () => {
    assert.equal('HELLO WORLD', petscii.to('hello world'));
  });

  it('should convert from petscii to ascii', () => {
    assert.equal('Hello World', petscii.to('hELLO wORLD'));
  });

  it('should replace CR with LF characters (to)', () => {
    assert.equal('Hello\rWorld', petscii.to('hELLO\nwORLD'));
  });

  it('should replace LF with CR characters (from)', () => {
    assert.equal('Hello\nWorl\nd', petscii.from('hELLO\rwORL\rD'));
  });

  it('should strip ctrl-z chars', () => {
    assert.equal('HelloWorld', petscii.to('hELLO\x1awORLD'));
  });

  it('should leave numeric characters unchanged', () => {
    assert.equal('123890', petscii.to('123890'));
  });
});
