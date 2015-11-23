#
#
#                     Nimrod Runtime Library
#                   for Serialization Using the
#                       Bittorrent Protocol
#
#                  (c) Copyright 2015 Tom Krauss
#
#
# The BPED module is an implementation of the Bittorrent ascii protocol.
# The Bittorrent protocol uses an ASCII representation of three basic types;
# integers, booleans, and strings.  In addition to the basic types, lists and
# dictionaries of the basic types are supported.
#
# This module supports the encoding of Strings, Integers, Lists, and
# Dictionaries including lists and dictionaries of mixed types.  A base class
# of BEncodeObject forms the basis for all encoding objects allowing the
# list and dictionary class to hold mixed types.
#
import
  tables,
  pegs,
  strutils



type
  BEncodeObject* = ref object of RootObj

  BInteger* = ref object of BEncodeObject
    data*: int

  BBoolean* = ref object of BEncodeObject
    data*: bool

  BString* = ref object of BEncodeObject
    data*: string

  BList* = ref object of BEncodeObject
    data*: seq[BEncodeObject]

  BDict* = ref object of BEncodeObject
    data*: OrderedTable[string, BEncodeObject]



method `$`*(this: BEncodeObject): string {.base.} = quit "must override!"
method encode*(this: BEncodeObject): string {.base.} = quit "must override!"
method decode*(this: BEncodeObject, buffer: string, start: int): int {.base.} = quit "must override!"


proc newBInteger*(value: int = 0): BInteger =
  ## Creation procedure for a BInteger type.
  return BInteger(data: value)

method `$`*(this: BInteger): string =
  ## Returns a nicely printable sting for a BInteger.
  return "BInteger(" & $this.data & ")"

method encode*(this: BInteger): string =
  ## Encodes an integer value into a string.
  return "i" & $this.data & "e"

proc isBIntegerAt*(buffer: string, start: int): bool =
  if buffer[start..len(buffer)] =~ peg"""^i{\-?\d*}e""":
    return true
  else:
    return false

method decode*(this: BInteger, buffer: string, start: int): int =
  ## Extracts an encoded integer value from the char buffer.  Returns the number
  ## of bytes consumed extracting the data.
  if buffer[start..len(buffer)] =~ peg"""^i{\-?\d*}e""":
    this.data = parseInt(matches[0])
    return len(matches[0]) + 2
  else:
    var e: ref OSError
    new(e)
    e.msg = "Unable to read integer from buffer."
    raise e



proc newBBoolean*(value: bool = false): BBoolean =
  ## Creation procedure for a BBoolean type.
  return BBoolean(data: value)

method `$`*(this: BBoolean): string =
  ## Returns a nicely printable sting for a BBoolean.
  return "BBoolean(" & $this.data & ")"

method encode*(this: BBoolean): string =
  ## Encodes an integer value into a string.
  if this.data: result = BInteger(data: 1).encode
  else:         result = BInteger(data: 0).encode

proc isBBooleanAt*(buffer: string, start: int): bool =
  return isBIntegerAt(buffer, start)

method decode*(this: BBoolean, buffer: string, start: int): int =
  ## Extracts an encoded boolean value from the char buffer.  Returns the number
  ## of bytes consumed extracting the data.
  var temp: BInteger = BInteger()
  var numBytes = temp.decode(buffer,start)
  case temp.data
  of 0:
    this.data = false
    return numBytes
  of 1:
    this.data = true
    return numBytes
  else:
    var e: ref OSError
    new(e)
    e.msg = "Unable to read integer from buffer."
    raise e


proc newBString*(value: string = ""): BString =
  ## Creation procedure for a BBoolean type.
  return BString(data: value)

method `$`*(this: BString): string =
  ## Returns a nicely printable sting for a BString.
  return "BString(\"" & $this.data & "\")"

method encode*(this: BString): string =
  ## Encodes a string value into a string.
  var len = len(this.data)
  return $len & ":" & this.data

proc isBStringAt*(buffer: string, start: int): bool =
  if buffer[start..len(buffer)] =~ peg"""^{\d*}\:""":
    return true
  else:
    return false

method decode*(this: BString, buffer: string, start: int): int =
  ## Extracts an encoded string value from the char buffer.  Returns the number
  ## of bytes consumed extracting the data.
  if buffer[start..len(buffer)] =~ peg"""^{\d*}\:""":
    var len = parseInt(matches[0])
    case len:
    of 0:
      this.data = ""
      result = 2
    else:
      result = len(matches[0]) + len + 1
      var off = start+len(matches[0])+1
      this.data = buffer[off .. off+len-1]
  else:
    var e: ref OSError
    new(e)
    e.msg = "Unable to read string from buffer."
    raise e




method `$`*(this: BList): string =
  ## Returns a nicely printable sting for a BList.
  result = "BList["
  var strs: seq[string] = @[]
  for i in low(this.data)..high(this.data):
    strs.add( $this.data[i] )
  result = result & join(strs,",") & "]"

method add*(this: BList, val: BEncodeObject) {.base.} =
  ## Adds a new BEncodeObject object to the BList.
  this.data.add(val)

method encode*(this: BList): string =
  ## Encodes a list of BEncodeObjects (a BList) into a string.
  result = "l"
  for a in this.data:
    result = result & a.encode()
  result = result & "e"

method decode*(this: BList, buffer: string, start: int): int =
  ## Extracts an encoded list from the char buffer.  Returns the number
  ## of bytes consumed extracting the data.
  if buffer[start] == 'l':
    var num = 1
    this.data = @[]
    while buffer[start+num] != 'e':
      if isBIntegerAt(buffer, start+num):
        var temp: BInteger = BInteger()
        num += temp.decode(buffer[start+num..len(buffer)], 0)
        this.data.add(temp)
      elif isBBooleanAt(buffer, start+num):
        var temp: BInteger = BInteger()
        num += temp.decode(buffer[start+num..len(buffer)], 0)
        this.data.add(temp)
      elif isBStringAt(buffer, start+num):
        var temp: BString = BString()
        num += temp.decode(buffer[start+num..len(buffer)], 0)
        this.data.add(temp)
      else:
        var e: ref OSError
        new(e)
        e.msg = "Unable to read BEncodeObject list from buffer."
        raise e
  else:
    var e: ref OSError
    new(e)
    e.msg = "Unable to read BEncodeObject list from buffer."
    raise e

proc newBList*(): BList =
  ## Creation procedure for a BList type.
  # We need to allocate the data sequence.
  result = BList(data: @[])

proc newBList*(value: openarray[int]): BList =
  ## Creation procedure for a BList type populated with the array of ints.
  result = newBList()
  for v in value:
    result.add(newBInteger(v))

proc newBList*(value: openarray[string]): BList =
  ## Creation procedure for a BList type with the array of strings.
  result = newBList()
  for v in value:
    result.add(newBString(v))

proc newBList*(value: openarray[bool]): BList =
  ## Creation procedure for a BList type with the array of strings.
  result = newBList()
  for v in value:
    result.add(newBBoolean(v))



method add*(this: BDict, key: string, val: BEncodeObject) {.base.} =
  ## Adds a new BEncodeObject object to the BDict.
  this.data.add(key,val)

method encode*(this: BDict): string =
  ## Encodes a table of BEncodeObjects (a BDict) into a string.
  result = "d"
  var temp = this.data
  temp.sort(proc (x, y: (string, BEncodeObject)): int = cmp(x,y))
  for key in keys(temp):
    result = result & encode(BString(data: key)) & encode(temp[key])
  result = result & "e"

method `$`*(this: BDict): string =
  ## Returns a nicely printable sting for a BDict.
  result = "BDict["
  var strs: seq[string] = @[]
  for key in keys(this.data):
    strs.add( key & "=>" & $this.data[key] )
  result = result & join(strs,",") & "]"


method decode*(this: BDict, buffer: string, start: int): int =
  ## Extracts an encoded dictionary from the char buffer.  Returns
  ## the number of bytes consumed extracting the data.
  if buffer[start] == 'd':
    var num = 1
    while buffer[start+num] != 'e':
      var tempKey = BString()
      num += tempKey.decode(buffer[start+num..len(buffer)], 0)

      if isBIntegerAt(buffer, start+num):
        var temp: BInteger = BInteger()
        num += temp.decode(buffer[start+num..len(buffer)], 0)
        this.data[tempKey.data] = temp
      elif isBBooleanAt(buffer, start+num):
        var temp: BInteger = BInteger()
        num += temp.decode(buffer[start+num..len(buffer)], 0)
        this.data[tempKey.data] = temp
      elif isBStringAt(buffer, start+num):
        var temp: BString = BString()
        num += temp.decode(buffer[start+num..len(buffer)], 0)
        this.data[tempKey.data] = temp
      else:
        var e: ref OSError
        new(e)
        e.msg = "Unable to read BEncodeObject dictionary from buffer."
        raise e
  else:
    var e: ref OSError
    new(e)
    e.msg = "Unable to read BEncodeObject dictionary from buffer."
    raise e


proc newBDict*(): BDict =
  ## Creation procedure for a BDict type.
  # We need to allocate the data table.
  var temp = BDict()
  temp.data = initOrderedTable[string, BEncodeObject]()
  return temp

proc newBDict*(pairs: openArray[(string, string)]): BDict =
  ## Creation procedure for a BDict type populated with the supplied
  ## mapping pairs.  The supplied pairs are (key, value) pairs of strings.
  var temp = newBDict()
  for v in pairs:
    temp.add(v[0], newBString(v[1]))
  return temp

proc newBDict*(pairs: openArray[(string, int)]): BDict =
  ## Creation procedure for a BDict type populated with the supplied
  ## mapping pairs.  The supplied pairs are (key, value) pairs with the
  ## key being a string and value being an integer.
  var temp = newBDict()
  for v in pairs:
    temp.add(v[0], newBInteger(v[1]))
  return temp

proc newBDict*(pairs: openArray[(string, bool)]): BDict =
  ## Creation procedure for a BDict type populated with the supplied
  ## mapping pairs.  The supplied pairs are (key, value) pairs with the
  ## key being a string and value being a boolean.
  var temp = newBDict()
  for v in pairs:
    temp.add(v[0], newBBoolean(v[1]))
  return temp
