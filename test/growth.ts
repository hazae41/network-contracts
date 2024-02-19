let total = 1n
let count = 1n
let supply = 0n

function sqrt(i: bigint) {
  let result = 1n;
  let current = 1n;

  while (current * current <= i) {
    result = current;
    current *= 2n;
  }

  return result
}

for (let i = 1n; i < 10000000000n; i++) {
  // const x = 1n // constant
  const x = i // linear
  // const x = sqrt(i) // square root
  // const x = i ** 2n // quadratic
  // const x = i ** 3n // cubic
  // const x = 2n ** i // exponential

  total += x
  count++

  const average = total / count
  const minted = x / average

  supply += minted

  console.log(x.toString(), total.toString(), supply.toString())
}

