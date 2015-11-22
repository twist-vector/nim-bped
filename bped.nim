#
#
#                     Nimrod Runtime Library
#                   for Serialization Using the
#                       Bittorrent Protocol
#
#                  (c) Copyright 2015 Tom Krauss
#
#
# This module is a partial implementation of the Bittorrent ascii protocol.
# Bittorrent uses an ASCII
#
# This is only a partial implementation of the Bittorrent protocol.  Bencoding
# supports the encoding of Strings, Integers, Lists, and Dictionaries
#

import
  unicode,
  pegs,
  strutils,
  tables



proc encode*(x: int): string =
  ## Encodes an integer value into a string.
  "i" & $x & "e"


proc decodeInteger*(buffer: string, start: int, value: var int): int =
  ## Extracts an encoded integer value from the char buffer.  Returns the number
  ## of bytes consumed extracting the data.
  if buffer[start..len(buffer)] =~ peg"""^i{\-?\d*}e""":
    value = parseInt(matches[0])
    result = len(matches[0]) + 2
  else:
    var e: ref OSError
    new(e)
    e.msg = "Unable to read integer from buffer."
    raise e


proc encode*(value: bool): string =
  ## Encodes a boolean value into a string.  Booleans are encoded as
  ## integers (1 for true, 0 for false)
  if value:
    encode(1)
  else:
    encode(0)

proc decodeBoolean*(buffer: string, start: int, value: var bool): int =
  ## Extracts an encoded boolean value from the char buffer.  Returns the number
  ## of bytes consumed extracting the data.
  var intVal: int
  result = decodeInteger(buffer, start, intVal)
  case intVal
  of 0:
    value = false
  of 1:
    value = true
  else:
    var e: ref OSError
    new(e)
    e.msg = "Unable to read boolean from buffer.  Found value: " &  $intVal
    raise e


proc encode*(value: string): string =
  ## Encodes a string value into a string.
  var len = len(value)
  $len & ":" & value


proc decodeString*(buffer: string, start: int, value: var string): int =
  ## Extracts an encoded string value from the char buffer.  Returns the number
  ## of bytes consumed extracting the data.
  if buffer[start..len(buffer)] =~ peg"""^{\d*}\:""":
    var len = parseInt(matches[0])
    case len:
    of 0:
      result = 2
      value = ""
    else:
      result = len(matches[0]) + len + 1
      var off = start+len(matches[0])+1
      value = buffer[start+off .. start+off+len-1]
  else:
    var e: ref OSError
    new(e)
    e.msg = "Unable to read string from buffer."
    raise e


proc encode*(x: seq[string]): string =
  result = "l"
  for i in low(x)..high(x):
    result = result & encode(x[i])
  result = result & "e"


proc decodeStringList*(buffer: string, start: int, value: var seq[string]): int =
  ## Extracts an encoded string list from the char buffer.  Returns the number
  ## of bytes consumed extracting the data.
  if buffer[start] == 'l':
    var num = 1
    var done = false
    while not done:
      var temp: string = ""
      try:
        num += decodeString(buffer[start+num..len(buffer)], 0, temp)
        value.add(temp)
      except:
        if buffer[start+num] != 'e':
          var e: ref OSError
          new(e)
          e.msg = "Unable to read string list from buffer."
          raise e
        else:
          done = true
          result = num + 1
  else:
    var e: ref OSError
    new(e)
    e.msg = "Unable to read string list from buffer."
    raise e


proc encode*(x: seq[int]): string =
  result = "l"
  for i in low(x)..high(x):
    result = result & encode(x[i])
  result = result & "e"


proc decodeIntegerList*(buffer: string, start: int, value: var seq[int]): int =
  ## Extracts an encoded integer list from the char buffer.  Returns the number
  ## of bytes consumed extracting the data.
  if buffer[start] == 'l':
    var num = 1
    var done = false
    while not done:
      var temp: int
      try:
        num += decodeInteger(buffer[start+num..len(buffer)], 0, temp)
        value.add(temp)
      except:
        if buffer[start+num] != 'e':
          var e: ref OSError
          new(e)
          e.msg = "Unable to read integer list from buffer - no ending 'e'."
          raise e
        else:
          done = true
          result = num + 1
  else:
    var e: ref OSError
    new(e)
    e.msg = "Unable to read integer list from buffer - unable to decode integer."
    raise e


proc encode*(dict: OrderedTable[string, string]): string =
  result = "d"
  var temp = dict
  temp.sort(proc (x, y: (string, string)): int = cmp(x,y))
  for key in keys(temp):
    result = result & encode(key) & encode(temp[key])
  result = result & "e"

proc decodeStringDict*(buffer: string, start: int, value: var OrderedTable[string, string]): int =
  ## Extracts an encoded dictionary of strings from the char buffer.  Returns
  ## the number of bytes consumed extracting the data.
  if buffer[start] == 'd':
    var num = 1
    var done = false
    while not done:
      var key, val: string
      try:
        num += decodeString(buffer[start+num..len(buffer)], 0, key)
        num += decodeString(buffer[start+num..len(buffer)], 0, val)
        value[key] = val
      except:
        if buffer[start+num] != 'e':
          var e: ref OSError
          new(e)
          e.msg = "Unable to read integer list from buffer - no ending 'e'."
          raise e
        else:
          done = true
          result = num + 1
  else:
    var e: ref OSError
    new(e)
    e.msg = "Unable to read integer list from buffer - unable to decode integer."
    raise e


proc encode*(dict: OrderedTable[string, int]): string =
  result = "d"
  var temp = dict
  temp.sort(proc (x, y: (string, int)): int = cmp(x,y))
  for key in keys(temp):
    result = result & encode(key) & encode(temp[key])
  result = result & "e"

proc decodeIntegerDict*(buffer: string, start: int, value: var OrderedTable[string, int]): int =
  ## Extracts an encoded dictionary of integers from the char buffer.  Returns
  ## the number of bytes consumed extracting the data.
  if buffer[start] == 'd':
    var num = 1
    var done = false
    while not done:
      var key: string
      var val: int
      try:
        num += decodeString(buffer[start+num..len(buffer)], 0, key)
        num += decodeInteger(buffer[start+num..len(buffer)], 0, val)
        value[key] = val
      except:
        if buffer[start+num] != 'e':
          var e: ref OSError
          new(e)
          e.msg = "Unable to read integer list from buffer - no ending 'e'."
          raise e
        else:
          done = true
          result = num + 1
  else:
    var e: ref OSError
    new(e)
    e.msg = "Unable to read integer list from buffer - unable to decode integer."
    raise e
