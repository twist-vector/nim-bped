##
#
#                     Nimrod Runtime Library
#                   for Serialization Using the
#                       Bittorrent Protocol
#
#                  (c) Copyright 2015 Tom Krauss
#
#
# This is a test driver for the Bittorrent serialization module.
# Running it should test the various edge cases for encoding/decoding.
#

import
  strutils,
  pegs,
  tables,
  bped

const
  padLength: int = 30


######
# Internal functions to "pretty print" encoded values
#

proc showBytes(x: string): string =
  result = "[" & x & "]"

proc checkit(v: int) =
  var res = encode(v)
  var numPadded: string = align($v, padLength)
  var check: int
  discard decodeInteger(res, 0, check)
  echo(numPadded & " -> " & showBytes(res) & " -> " & $check)

proc checkit(v: bool) =
  var res = encode(v)
  var numPadded: string = align($v, padLength)
  var check: bool
  discard decodeBoolean(res, 0, check)
  echo(numPadded & " -> " & showBytes(res) & " -> " & $check)

proc checkit(v: string) =
  var res = encode(v)
  var numPadded: string = align($v, padLength)
  var check: string = ""
  discard decodeString(res, 0, check)
  echo(numPadded & " -> " & showBytes(res) & " -> " & $check)

proc checkit(v: seq[string]) =
  var res = encode(v)
  var numPadded: string = align($v, padLength)
  var check: seq[string] = @[]
  discard decodeStringList(res, 0, check)
  echo(numPadded & " -> " & showBytes(res) & " -> " & $check)

proc checkit(v: seq[int]) =
  var res = encode(v)
  var numPadded: string = align($v, padLength)
  var check: seq[int] = @[]
  discard decodeIntegerList(res, 0, check)
  echo(numPadded & " -> " & showBytes(res) & " -> " & $check)

proc checkit(v: OrderedTable[string, string]) =
  var res = encode(v)
  var numPadded: string = align($v, padLength)
  var check = initOrderedTable[string, string]()
  discard decodeStringDict(res, 0, check)
  echo(numPadded & " -> " & showBytes(res) & " -> " & $check)


proc checkit(v: OrderedTable[string, int]) =
  var res = encode(v)
  var numPadded: string = align($v, padLength)
  var check = initOrderedTable[string, int]()
  discard decodeIntegerDict(res, 0, check)
  echo(numPadded & " -> " & showBytes(res) & " -> " & $check)



echo("Checking integers...")
checkit(0)
checkit(10)
checkit(-42)
echo ""

echo("Checking booleans...")
checkit(true)
checkit(false)
echo ""

echo("Checking strings...")
checkit("hello")
checkit("This is a longer string")
checkit("")
echo ""

echo("Checking string lists...")
checkit( @["one", "two", "three"] )
var a: seq[string] = @[]
checkit(a)
echo ""

echo("Checking integer lists...")
checkit( @[1,2,3] )
checkit( @[-1,12345,0] )
var b: seq[int] = @[]
checkit(b)
echo ""

echo("Checking string dictionary (order may change)...")
var dict = initOrderedTable[string, string]()
dict["spam"] = "eggs"
dict["cow"] = "moo"
checkit(dict)
var dict2 = initOrderedTable[string, string]()
checkit(dict2)
echo ""

echo("Checking integer dictionary (order may change)...")
var dict3 = initOrderedTable[string, int]()
dict3["spam"] = 1
dict3["cow"] = 42
checkit(dict3)
var dict4 = initOrderedTable[string, int]()
checkit(dict4)
echo ""
