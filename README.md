# Network Contracts

## Status

### Beta

[DEPLOYED ON GNOSIS](https://gnosisscan.io/address/0xF1eC047cbd662607BBDE9Badd572cf0A23E1130B)

## Constraints

We want a function that

1) can be proven with zero-knowledge
2) is optimized for both EVM and for end-user devices (e.g. node, browser)
3) emits tokens at a constant rate (even if the hashrate grows unexpectedly)

### Zero-Knowledge Proof

To achieve zero-knowledge proving, the client generates a (supposedly random) secret that is hashed twice, the first step is just hashing the secret to make it a proof. The second hash is to mix the proof with various parameters to avoid replay and ensure it has no value if in the wrong hands. 

Those parameters are

#### Receiver address 

A secret is only valuable to you if its hash is valuable to you. If someone steals your secrets, he would have to check if they are valuable to him, which is the same computation as mining them.

#### Contract address

A secret is only valuable on a specific contract. This allows deploying multiple versions of the token on the same chain. 

#### Chain ID

A secret is only valuable on a specific chain. This allows deploying the token on another chain. This is needed because contracts can have the same address on different chains.

#### —

So when I send you a proof, this proves that I know a secret whose hash is valuable to you. And since proofs are deduplicated on the receiver side, no one can replay them.

```tsx
let secrets = []
let proofs = []
let total = 0

while (total < price) {
  const secret = random()
  const proof = keccak256(secret)
  const value = keccak256(proof, receiver, contract, chain)
  
  secrets.push(secret)
  proofs.push(proof)
  total += value
}
```

Of course, someone can randomly generate proofs and check them for value before sending them, skiping the first hash and saving resources.

```tsx
let proofs = []
let total = 0

while (total < price) {
  const proof = random() // lol
  const value = keccak256(proof, receiver, contract, chain)

  proofs.push(proof)
  total += value
}
```

But this would still require half the computation. So a server receiving some proofs should only account them for half their value.

Also, since you can have a reputation protocol on top of Network, then spoofing proofs can most of the time only be done once.

### Optimizations

We use the `Keccak-256` (`SHA-3`) hashing function, it's the best compromise between gas efficiency on EVM, strong unguessability, implementation in many languages, and especially WebAssembly compatible.

Then, parameters are encoded using ABI, which in this case is raw bytes concatening, this ensures no expensive conversion between raw bytes and other types such as hex string and bigint (e.g. on JavaScript runtimes). This allows to directly put the first keccak256 output into the second keccak256 input. Especially when using WebAssembly.

```tsx
const mixin = concat(empty, receiver, contract, chain) // <-- empty slot for the proof

while (true) {
  const secret = random()
  const proof = keccak256(secret) // <--- zero-conversion and zero-copy

  mixin.set(0, proof) // <--- directly copy the proof into the mixin at offset 0

  const value = keccak256(mixin) // <--- zero-conversion and zero-copy
}
```

### Emission

Each value is divided by the average. This ensures that the emission rate remains constant (linear emission), even when the hashrate power grows unexpectedly.

More specifically, we compute the total value (whose derivative is the value), and the total count (whose derivative is 1).

```tsx
let total = 0n
let count = 0n
let supply = 0n

function emit(value: bigint) {
  total += value
  count += 1

  supply += ???
}
```

So to increase the supply constantly, we need a way to reduce the value to a constant `c` even if the value grows in unexpected ways over time.

```
c
= f' / f 
= (total' / count') / (total / count)
= (value / 1) / (total / count)
= value / average
```

Since `total / count` is the average of all values, we essentially divide the value by the average.

This works when `value` over time (= the hashrate) is
- constant (no grow) -> average is constant too -> emission is constant
- linear -> average is linear too -> emission is constant
- sublinear -> average is sublinear too -> emission is constant
- quadratic -> average is quadratic too -> emission is constant
- cubic -> average is cubic too -> emission is constant

Running this script will show you a linear supply

```tsx
let total = 1n
let count = 1n
let supply = 0n

for (let i = 1n; i < 1000000000n; i++) {
  // const x = 1n // constant
  // const x = i // linear
  const x = i ** 2n // quadratic
  // const x = i ** 3n // cubic
  // const x = 2n ** i // exponential

  total += x
  count += 1

  const average = total / count
  const minted = x / average

  supply += minted

  console.log(x.toString(), total.toString(), supply.toString())
}
```

One of the exceptions is if the hashrate is exponential (`c^(x)` for any `c`). This doesn't work because the average can't keep up with the value, since the value is the previous total at each iteration.