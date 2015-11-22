# Nim Bittorrent Protocol Ecnoding and Decoding (BPED)

The *BPED* module is a partial implementation of the Bittorrent ascii protocol.
Bittorrent uses an ASCII

This is only a partial implementation of the Bittorrent protocol.  BPED
currently supporting uniform containers.  Mixed lists or dictionaries (e.g., a
list containing both strings and integers) is not supported.

For the Bittorrent encoding spec, see [https://wiki.theory.org/BitTorrentSpecification#Bencoding](https://wiki.theory.org/BitTorrentSpecification#Bencoding)

## Supported
    - Booleans (as integers)
    - Strings
    - Integers
    - Lists
      - of strings
      - of integers
    - Dictionaries
      - of strings
      - of integers

## Unsupported:
- lists of mixed types (strings and integers)
- dictionaries of mixed types (strings and integers)
