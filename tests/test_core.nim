discard """
"""
import hannah
import std/[os, strformat]

var state = newXxh32()
state.update("Nobody ")
state.update("inspects ")
state.update("the spammish ")
state.update("repetition")
assert state.digest() == 3794352943'u32
assert $state == $3794352943'u32
state.reset()


let tmpFilePath = "./.temp.txt"
discard execShellCmd(&"echo foo > {tmpFilePath}")

assert streamingHashXxH3_64(tmpFilePath) == "af6f0665deabb67a"

discard execShellCmd(&"echo meow to you > {tmpFilePath}")
assert  streamingHashXxH3_64(tmpFilePath) == "4c98fab07f8210a3"

discard execShellCmd(fmt"rm {tmpFilePath}")
