
// https://en.wikipedia.org/wiki/PETSCII

function to(input) {
  const sanitizedInput = input
    .replace(/\n/g, '@@@')
    .replace(/\r/g, '')
    .replace(/_/g, '-')
    .replace(/`/g, '"')
    .replace(/[^A-Za-z 0-9 \.,\?""!@#\$%\^&\*\(\)-_=\+;:<>\/\\\|\}\{\[\]`~]*/g, '');

  let petsciiString = '';
  for (let i = 0; i < sanitizedInput.length; i++) {
    const ascii = sanitizedInput.charCodeAt(i);
    if (ascii >= 65 && ascii <= 90) {
      petsciiString += String.fromCharCode(ascii + 32);
    } else if (ascii >= 97 && ascii <= 122) {
      petsciiString += String.fromCharCode(ascii - 32);
    } else {
      petsciiString += sanitizedInput[i];
    }
  }
  petsciiString = petsciiString.replace(/@@@/g, '\x0d');
  return petsciiString;
}

function from(input) {
  let asciiString = '';
  for (let i = 0; i < input.length; i++) {
    const ascii = input.charCodeAt(i);
    if (ascii >= 65 && ascii <= 90) {
      asciiString += String.fromCharCode(ascii - 32);
    } else if (ascii >= 97 && ascii <= 122) {
      asciiString += String.fromCharCode(ascii + 32);
    } else {
      asciiString += input[i];
    }
  }
  return asciiString;
}


module.exports = {
  to,
  from
};
