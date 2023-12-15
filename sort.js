let winNumbers = [ 5,13,11,7,7,16];

function sortArray() {
  for (let i = 1; i < winNumbers.length; i++) {
    let swapped = false;
    for (let n = 0; n < winNumbers.length - i; n++) {
      let second = winNumbers[n + 1];
      let first = winNumbers[n];
      if (second < first) {
        winNumbers[n] = second;
        winNumbers[n + 1] = first;
        swapped = true;
      }
    }
    if (!swapped) {
      return winNumbers;
    }
  }
  return winNumbers;
}

const output = sortArray();
console.log("");
console.log(output);
