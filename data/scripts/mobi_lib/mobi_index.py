#!/usr/bin/env python
# vim:fileencoding=UTF-8:ts=4:sw=4:sta:et:sts=4:ai

DEBUG = False

import sys
import array, struct, os, re

from mobi_utils import toHex, toBin, getVariableWidthValue, getLanguage, readTagSection, toBase32, fromBase32

class MobiIndex:
    def __init__(self, sect):
        self.sect = sect

    def getIndexData(self, idx):
        sect = self.sect
        outtbl = []
        ctoc_text = {}
        if idx != 0xffffffff:
            data = sect.loadSection(idx)
            idxhdr = self.parseINDXHeader(data)
            IndexCount = idxhdr['count']
            # handle the case of multiple sections used for CTOC
            rec_off = 0
            off = idx + IndexCount + 1
            for j in range(idxhdr['nctoc']):
                cdata = sect.loadSection(off + j)
                ctocdict = self.readCTOC(cdata)
                for k in ctocdict.keys():
                    ctoc_text[k + rec_off] = ctocdict[k]
                rec_off += 0x10000
            tagSectionStart = idxhdr['len']
            controlByteCount, tagTable = readTagSection(tagSectionStart, data)
            if DEBUG:
                print "IndexCount is", IndexCount
                print "TagTable: %s" % tagTable
            for i in range(idx + 1, idx + 1 + IndexCount):
                data = sect.loadSection(i)
                hdrinfo = self.parseINDXHeader(data)
                idxtPos = hdrinfo['start']
                entryCount = hdrinfo['count']
                if DEBUG:
                    print idxtPos, entryCount
                # loop through to build up the IDXT position starts
                idxPositions = []
                for j in range(entryCount):
                    pos, = struct.unpack_from('>H', data, idxtPos + 4 + (2 * j))
                    idxPositions.append(pos)
                # The last entry ends before the IDXT tag (but there might be zero fill bytes we need to ignore!)
                idxPositions.append(idxtPos)
                # for each entry in the IDXT build up the tagMap and any associated text
                for j in range(entryCount):
                    startPos = idxPositions[j]
                    endPos = idxPositions[j+1]
                    textLength = ord(data[startPos])
                    text = data[startPos+1:startPos+1+textLength]
                    tagMap = self.getTagMap(controlByteCount, tagTable, data, startPos+1+textLength, endPos)
                    outtbl.append([text, tagMap])
                    if DEBUG:
                        print tagMap
                        print text
        return outtbl, ctoc_text

    def getTagMap(self, controlByteCount, tagTable, entryData, startPos, endPos):
        '''
        Create a map of tags and values from the given byte section.

        @param controlByteCount: The number of control bytes.
        @param tagTable: The tag table.
        @param entryData: The data to process.
        @param startPos: The starting position in entryData.
        @param endPos: The end position in entryData or None if it is unknown.
        @return: Hashmap of tag and list of values.
        '''
        tags = []
        tagHashMap = {}
        controlByteIndex = 0
        dataStart = startPos + controlByteCount

        for tag, valuesPerEntry, mask, endFlag in tagTable:
            if endFlag == 0x01:
                controlByteIndex += 1
                continue
            value = ord(entryData[startPos + controlByteIndex]) & mask
            if value != 0:
                if value == mask:
                    if self.countSetBits(mask) > 1:
                        # If all bits of masked value are set and the mask has more than one bit, a variable width value
                        # will follow after the control bytes which defines the length of bytes (NOT the value count!)
                        # which will contain the corresponding variable width values.
                        consumed, value = getVariableWidthValue(entryData, dataStart)
                        dataStart += consumed
                        tags.append((tag, None, value, valuesPerEntry))
                    else:
                        tags.append((tag, 1, None, valuesPerEntry))
                else:
                    # Shift bits to get the masked value.
                    while mask & 0x01 == 0:
                        mask = mask >> 1
                        value = value >> 1
                    tags.append((tag, value, None, valuesPerEntry))
        for tag, valueCount, valueBytes, valuesPerEntry in tags:
            values = []
            if valueCount != None:
                # Read valueCount * valuesPerEntry variable width values.
                for _ in range(valueCount):
                    for _ in range(valuesPerEntry):
                        consumed, data = getVariableWidthValue(entryData, dataStart)
                        dataStart += consumed
                        values.append(data)
            else:
                # Convert valueBytes to variable width values.
                totalConsumed = 0
                while totalConsumed < valueBytes:
                    # Does this work for valuesPerEntry != 1?
                    consumed, data = getVariableWidthValue(entryData, dataStart)
                    dataStart += consumed
                    totalConsumed += consumed
                    values.append(data)
                if totalConsumed != valueBytes:
                    print "Error: Should consume %s bytes, but consumed %s" % (valueBytes, totalConsumed)
            tagHashMap[tag] = values
        # Test that all bytes have been processed if endPos is given.
        if endPos is not None and dataStart != endPos:
            # The last entry might have some zero padding bytes, so complain only if non zero bytes are left.
            for char in entryData[dataStart:endPos]:
                if char != chr(0x00):
                    print "Warning: There are unprocessed index bytes left: %s" % toHex(entryData[dataStart:endPos])
                    if DEBUG:
                        print "controlByteCount: %s" % controlByteCount
                        print "tagTable: %s" % tagTable
                        print "data: %s" % toHex(entryData[startPos:endPos])
                        print "tagHashMap: %s" % tagHashMap
                    break

        return tagHashMap


    def countSetBits(self, value, bits = 8):
        '''
        Count the set bits in the given value.

        @param value: Integer value.
        @param bits: The number of bits of the input value (defaults to 8).
        @return: Number of set bits.
        '''
        count = 0
        for _ in range(bits):
            if value & 0x01 == 0x01:
                count += 1
            value = value >> 1
        return count

    def parseINDXHeader(self, data):
        "read INDX header"
        if not data[:4] == 'INDX':
            print "Warning: index section is not INDX"
            return False
        words = (
                'len', 'nul1', 'type', 'gen', 'start', 'count', 'code',
                'lng', 'total', 'ordt', 'ligt', 'nligt', 'nctoc'
        )
        num = len(words)
        values = struct.unpack('>%dL' % num, data[4:4*(num+1)])
        header = {}
        for n in range(num):
            header[words[n]] = values[n]
        if DEBUG:
            print "parsed INDX header:"
            for n in words:
                print n, "%X" % header[n],
            print
        return header

    def readCTOC(self, txtdata):
        # read all blocks from CTOC
        ctoc_data = {}
        offset = 0
        while offset<len(txtdata):
            if txtdata[offset] == '\0':
                break
            idx_offs = offset
            #first n bytes: name len as vwi
            pos, ilen = getVariableWidthValue(txtdata, offset)
            offset += pos
            #<len> next bytes: name
            name = txtdata[offset:offset+ilen]
            offset += ilen
            if DEBUG:
                print "name length is ", ilen
                print idx_offs, name
            ctoc_data[idx_offs] = name
        return ctoc_data
