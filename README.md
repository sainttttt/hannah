
# Hannah![hannah-logo](https://github.com/user-attachments/assets/ee053547-07e2-415d-92da-f2ee8db484b1)

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
