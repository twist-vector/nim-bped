# Nim Bittorrent Protocol Encoding and Decoding (BPED)

The *BPED* module is an implementation of the Bittorrent ascii protocol.
The Bittorrent protocol uses an ASCII representation of three basic types;
integers, booleans, and strings.  In addition to the basic types, lists and
dictionaries of the basic types are supported.

For the Bittorrent encoding spec, see [https://wiki.theory.org/BitTorrentSpecification#Bencoding](https://wiki.theory.org/BitTorrentSpecification#Bencoding)

## Supported
    - Booleans (as integers)
    - Strings
    - Integers
    - Lists of mixed strings, integers, and/or booleans
    - String indexed dictionaries of mixed strings, integers, and/or booleans

## Examples

Declaring and populating the underlying type is fairly straightforward.  There
are construction function `make*` for each type as well as convenience functions
 for a few common uses.
```nim
import bped

let
  b0 = newBBoolean(false)
  i0 = newBInteger(42)
  s0 = newBString("hello")
  l0 = newBList()
  d0 = newBDict()
```
the "stringizer" operator `$` is overloaded for all types so it is simple to
display the current value of any type from the module.  The above would be
displayed with
```nim
echo b0
echo i0
echo s0
echo l0
echo d0
```
the resulting output would
```
BBoolean(false)
BInteger(42)
BString("hello")
BList[]
BDict[]
```
It's simple to initialize the value as seen above.  After creation, the
value can be changed directly by modifying the underlying data.
```
b0.data = true
i0.data = 24
s0.data = "world"
l0 = newBList()
d0 = newBDict()
```
for the list and dictionary types there are convenience functions `add` which
adds a BEncodeObject to the list )or dictionary).  Note that the Bittorrent
protocol supports dictionaries indexed by string only.  To add items to the
list or dictionary:
```nim
l0.add(newBInteger(14))
l0.add(newBString("world"))
d0.add("cow", newBString("moo"))
```
which would result in the following output from echo:
```
BList[BInteger(14),BString("world")]
BDict[cow=>BString("moo")]
```
## Encode
The ability to create the encoding objects is not very interesting unless they
can be represented in the correct Bittorrent protocol.  Each type supports an
`encode` method that returns the ASCCI representation of the underlying data.
To see the encoded representation,
```nim
echo b0, " -> ", b0.encode()
echo i0, " -> ", i0.encode()
echo s0, " -> ", s0.encode()
echo l0, " -> ", l0.encode()
echo d0, " -> ", d0.encode()
```
which shows
```
BBoolean(true) -> i1e
BInteger(24) -> i24e
BString("world") -> 5:world
BList[BInteger(14),BString("world")] -> li14e5:worlde
BDict[cow=>BString("moo")] -> d3:cow3:mooe
```

## Decode
Decoding of the protocol is a little more complicated.  It is anticipated that
the decoding of individual pieces of data occurs in the larger context of
parsing a received longer sting.  As such, the decode methods have a signature
```nim
method decode*(this: BEncodeObject, buffer: string, start: int): int
```
where the string buffer containing the encoded data is provided in `buffer`.
IIt is expected that `start` is the location within the buffer from which data
should be extracted.  The return integer is the number of bytes "consumed" in
decoding the requested data.  For instance, a collection of data encoded into
the protocol string would be generated as
```nim
let encString = b0.encode() & i0.encode() & s0.encode()
echo encString
```
which creates the protocol string `i1ei24e5:world`.  This would be decoded with
```nim
var be = newBBoolean()
var ie = newBInteger()
var se = newBString()
var numBytes = 0
numBytes += be.decode(encString, numBytes)
numBytes += ie.decode(encString, numBytes)
numBytes += se.decode(encString, numBytes)
echo be
echo ie
echo se
```

## Caveats and TODO
Since the Bittorrent encoding supports lists and dictionaries with mixed types
a hierarchy of `BEncodeObject` types was created.  This makes interfacing with
other libraries a little less convenient since the result of, for example, a
list decode is a BList rather than a Nim @[].  Further, each item in the
BList is a derived class of the BEncodeObject class meaning it you'll need to
access the underlying data item to use in your Nim code.

Second, the Bittorrent protocol does not have a dedicated Boolean type.  Rather
booleans are encoded simply as integers.  This makes it difficult to extract
them from a stream with unknown format.  That is, if you're decoding an incoming
stream and encounter the encoded value `i1e` the resulting data could be either
the integer "1" or a boolean logical "true".
