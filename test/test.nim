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
  var res: string = BInteger(data: v).encode()
  var numPadded: string = align($v, padLength)
  var temp: BInteger = BInteger()
  discard temp.decode(res, 0)
  echo(numPadded & " -> " & showBytes(res) & " -> " & $temp.data)

proc checkit(v: bool) =
  var res: string = BBoolean(data: v).encode()
  var numPadded: string = align($v, padLength)
  var temp: BBoolean = BBoolean()
  discard temp.decode(res, 0)
  echo(numPadded & " -> " & showBytes(res) & " -> " & $temp.data)

proc checkit(v: string) =
  var res: string = BString(data: v).encode()
  var numPadded: string = align($v, padLength)
  var temp: BString = BString()
  discard temp.decode(res, 0)
  echo(numPadded & " -> " & showBytes(res) & " -> " & $temp.data)

proc checkit(v: BList) =
  var res = encode(v)
  var numPadded: string = align($v.data, padLength)
  var check: BList = newBList()
  discard check.decode(res, 0)
  echo(numPadded & " -> " & showBytes(res) & " -> " & $check.data)

proc checkit(v: BDict) =
  var res = encode(v)
  var numPadded: string = align($v, padLength)
  var check = newBDict()
  discard check.decode(res, 0)
  echo(numPadded & " -> " & showBytes(res) & " -> " & $check.data)


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

echo("Checking mixed lists...")
var blist: BList = newBList()
blist.add(BBoolean(data: true))
blist.add(BString(data: "Hello"))
blist.add(BInteger(data: 42))
checkit(blist)
checkit(newBList())
echo ""

echo("Checking string dictionary (order may change)...")
var dict = newBDict()
dict.add("spam", BString(data: "eggs"))
dict.add("fortytwo", BInteger(data: 42))
dict.add("itstrue", BBoolean(data: true))
echo dict
checkit(dict)
