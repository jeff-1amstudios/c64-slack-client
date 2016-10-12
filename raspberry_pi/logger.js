
function log() {
  // write debug messages to stderr as stdout is read by c64 emulator
  console.error.apply(console, arguments);
}

module.exports = {
  log
};
