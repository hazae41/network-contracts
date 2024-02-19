let total = 1n
let count = 1n
let supply = 0n

for (let i = 1n; i < 20n; i++) {
  // const x = 1n // constant
  // const x = i // linear
  const x = i ** 2n // quadratic
  // const x = i ** 3n // cubic
  // const x = 2n ** i // exponential
  // const x = ((50n * i) / 100n) + 1n // sublinear

  total += x
  count++

  const average = total / count
  const minted = x / average

  supply += minted

  console.log(x.toString(), total.toString(), supply.toString())
}

