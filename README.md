![hannah-logo](https://github.com/user-attachments/assets/c23a1737-36f1-4783-8639-6b82f5a4bc26)

# Hannah
Hash library for Nim, currently supports xxhash

```
nimble install hannah
```

Usage:

```
hash = streamingHashXxH3_64(largefilePath, seed)
echo hash
```

```
var state = newXxh32()
state.update(msg)
assert state.digest() == msgh32
assert $state == $msgh32

state.reset()
state.update("Nobody ")
state.update("inspects ")
state.update("the spammish ")
state.update("repetition")
assert state.digest() == 3794352943'u32
assert $state == $3794352943'u32
state.reset()
```
