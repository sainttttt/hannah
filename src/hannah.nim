{.compile: "xxHash/xxhash.c".}

import std/[math, streams, strutils]

# One-shot functions
proc XXH32*(input: ptr UncheckedArray[byte], length: csize_t, seed: uint32): uint32 {.cdecl, importc: "XXH32".}
proc XXH64*(input: ptr UncheckedArray[byte], length: csize_t, seed: uint64): uint64  {.cdecl, importc: "XXH64".}

proc XXH32*(input: cstring, length: int, seed: uint32): uint32 {.inline.} =
  XXH32(cast[ptr UncheckedArray[byte]](input), length.csize_t, seed)

proc XXH64*(input: cstring, length: int, seed: uint64): uint64 {.inline.} =
  XXH64(cast[ptr UncheckedArray[byte]](input), length.csize_t, seed)

proc XXH32*(input: string, seed = 0): uint32 {.inline.} =
  XXH32(input.cstring, input.len, seed.uint32)

proc XXH64*(input: string, seed = 0): uint64 {.inline.} =
  XXH64(input.cstring, input.len, seed.uint64)

proc XXH3_64bits*(input: ptr UncheckedArray[byte], length: csize_t): uint64 {.cdecl, importc: "XXH3_64bits".}
proc XXH3_64bits_withSeed*(input: ptr UncheckedArray[byte], length: csize_t, seed: uint64): uint64 {.cdecl, importc: "XXH3_64bits_withSeed".}

proc XXH3_64bits*(input: string): uint64 =
  XXH3_64bits(cast[ptr UncheckedArray[byte]](unsafeAddr input[0]), input.len.csize_t)
proc XXH3_64bits_withSeed*(input: string, seed: uint64): uint64 =
  XXH3_64bits_withSeed(cast[ptr UncheckedArray[byte]](unsafeAddr input[0]), input.len.csize_t, seed)

# Streaming api
type
  LLxxh64State* = pointer
  LLxxh32State* = pointer
  LLxxh3_64State* = pointer
  Xxh32State* = object
    llstate*: LLxxh32State # wrapped in a object for destructor
  Xxh64State* = object
    llstate*: LLxxh64State # wrapped in a object for destructor
  Xxh3_64State* = object
    llstate*: LLxxh3_64State # wrapped in a object for destructor

proc XXH32_createState*(): LLxxh32State {.cdecl, importc: "XXH32_createState".}
proc XXH32_freeState*(state: LLxxh32State) {.cdecl, importc: "XXH32_freeState".}
proc XXH32_reset*(state: LLxxh32State, seed: uint32 = 0) {.cdecl, importc: "XXH32_reset".}
proc XXH32_update*(state: LLxxh32State, input: cstring, len: int) {.cdecl, importc: "XXH32_update".}
proc XXH32_digest*(state: LLxxh32State): uint32 {.cdecl, importc: "XXH32_digest".}

proc newXxh32*(seed: uint32 = 0): Xxh32State =
  result.llstate = XXH32_createState()
  result.llstate.XXH32_reset(seed)

proc update*(state: Xxh32State, input: string) =
  state.llstate.XXH32_update(input.cstring, input.len)

proc digest*(state: Xxh32State): uint32 =
  return state.llstate.XXH32_digest()

proc `$`*(state: Xxh32State): string =
  return $state.digest

proc reset*(state: Xxh32State, seed = 0'u32) =
  state.llstate.XXH32_reset(seed)

proc `=destroy`*(state: var Xxh32State) =
  state.llstate.XXH32_freeState()


proc XXH3_createState*(): LLxxh3_64State {.cdecl, importc: "XXH3_createState".}
proc XXH3_freeState*(state: LLxxh3_64State) {.cdecl, importc: "XXH3_freeState".}
proc XXH3_64_reset*(state: LLxxh3_64State) {.cdecl, importc: "XXH3_64bits_reset".}
proc XXH3_64_reset_withSeed*(state: LLxxh3_64State, seed: uint64 = 0) {.cdecl, importc: "XXH3_64bits_reset_withSeed".}
proc XXH3_64_update*(state: LLxxh3_64State, input: cstring, len: int) {.cdecl, importc: "XXH3_64bits_update".}
proc XXH3_64_digest*(state: LLxxh3_64State): uint64 {.cdecl, importc: "XXH3_64bits_digest".}

proc newXxH3_64*(seed: uint64 = 0): XxH3_64State =
  result.llstate = XXH3_createState()
  result.llstate.XXH3_64_reset_withSeed(seed)

proc update*(state: XxH3_64State, input: string) =
  state.llstate.XXH3_64_update(input.cstring, input.len)

proc digest*(state: XxH3_64State): uint64 =
  return state.llstate.XXH3_64_digest()

proc `$`*(state: XxH3_64State): string =
  return $state.digest

proc reset*(state: XxH3_64State, seed = 0'u64) =
  state.llstate.XXH3_64_reset_withSeed(seed)

proc `=destroy`*(state: var XxH3_64State) =
  state.llstate.XXH3_freeState()

# so this is what chunk size we use to do the streaming
# segmented hash thing. This number seems to be tweakable
# and there seems to be a sweet spot for speed, too small
# or too large affects the speed. Idk if this is the right
# approach or what

# Also I wanted to optimize it by not creating a newString
# but there was a bug, the hash works but it varies each time
# you call it, so something is not right. I think the speed increase
# is extremely minimal so it's not worth it. Was just doing it for
# fun really

# var buffer = newSeqUninitialized[uint8](chunkSize)
# var buffer = newString(chunkSize)
var buffer: string
var bufferAlloced = false

proc streamingHashXxH3_64*(path: string, seed:uint64 = 0, chunkSize = 2 ^ 17): string =
  if not bufferAlloced:
    bufferAlloced = true
    buffer = newString(chunkSize)

  var fs = newFileStream(path, fmRead)
  defer: fs.close()

  var state = newXxh3_64(seed)
  var size: int

  while not fs.atEnd:
    fs.readStr(chunkSize, buffer)
    # let size = fs.readData(addr(buffer[0]), chunkSize - 1)
    # buffer[size] = 0

    state.update(cast[string](buffer))

  return state.digest().toHex.toLowerAscii



proc XXH64_createState*(): LLxxh64State {.cdecl, importc: "XXH64_createState".}
proc XXH64_freeState*(state: LLxxh64State) {.cdecl, importc: "XXH64_freeState".}
proc XXH64_reset*(state: LLxxh64State, seed: uint64 = 0) {.cdecl, importc: "XXH64_reset".}
proc XXH64_update*(state: LLxxh64State, input: cstring, len: int) {.cdecl, importc: "XXH64_update".}
proc XXH64_digest*(state: LLxxh64State): uint64 {.cdecl, importc: "XXH64_digest".}

proc newXxh64*(seed: uint64 = 0): Xxh64State =
  result.llstate = XXH64_createState()
  result.llstate.XXH64_reset(seed)

proc update*(state: Xxh64State, input: string) =
  state.llstate.XXH64_update(input.cstring, input.len)

proc digest*(state: Xxh64State): uint64 =
  return state.llstate.XXH64_digest()

proc `$`*(state: Xxh64State): string =
  return $state.digest

proc reset*(state: Xxh64State, seed = 0'u64) =
  state.llstate.XXH64_reset(seed)

proc `=destroy`*(state: var Xxh64State) =
  state.llstate.XXH64_freeState()

when isMainModule:
  block:
    # One Shot
    assert 3794352943'u32 == XXH32("Nobody inspects the spammish repetition")
    assert 0xB559B98D844E0635'u64 == XXH64("xxhash", 20141025)

  block:
    assert 0x7051CC31E84FF73'u64 == XXH3_64bits("meow")
    assert 0x4268DCFE699316D8'u64 == XXH3_64bits_withSeed("meow meow meow", 42)
    assert XXH3_64bits("Abracadabra") == XXH3_64bits_withSeed("Abracadabra", 0)

  const msg = "foo"
  const msgh32 = 0xe20f0dd9'u32
  const msgh64 = 0x33bf00a859c4ba3f'u64
  block:
    # LowLevel Streaming 64bit
    let state64 = XXH64_createState()
    state64.XXH64_reset()
    state64.XXH64_update(msg.cstring, msg.len)
    assert state64.XXH64_digest() == XXH64(msg)
    assert state64.XXH64_digest() == msgh64
    XXH64_freeState(state64)

  block:
    # LowLevel Streaming 32bit
    let state32 = XXH32_createState()
    state32.XXH32_reset()
    state32.XXH32_update(msg.cstring, msg.len)
    assert state32.XXH32_digest() == XXH32(msg)
    assert state32.XXH32_digest() == msgh32
    XXH32_freeState(state32)

  block:
    # HighLevel Streaming 32bit
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

  block:
    # HighLevel Streaming 64bit
    var state = newXxh64()
    state.update(msg)
    assert state.digest() == msgh64
    assert $state == $msgh64
    state.reset()
