#!/usr/bin/env python
# vim:fileencoding=UTF-8:ts=4:sw=4:sta:et:sts=4:ai

DEBUG_DICT = False

import sys
import array, struct, os, re, imghdr

from mobi_utils import toHex, toBin, getVariableWidthValue, getLanguage, readTagSection

class dictSupport:
    def __init__(self, mh, sect):
        self.mh = mh
        self.header = mh.header
        self.sect = sect
        self.metaOrthIndex = mh.metaOrthIndex
        self.metaInflIndex = mh.metaInflIndex

    def getPositionMap (self):
        header = self.header
        sect = self.sect

        positionMap = {}

        metaOrthIndex = self.metaOrthIndex
        metaInflIndex = self.metaInflIndex

        decodeInflection = True
        if metaOrthIndex != 0xFFFFFFFF:
            print "Info: Document contains orthographic index, handle as dictionary"
            if metaInflIndex == 0xFFFFFFFF:
                decodeInflection = False
            else:
                metaInflIndexData = sect.loadSection(metaInflIndex)
                metaIndexCount, = struct.unpack_from('>L', metaInflIndexData, 0x18)
                if metaIndexCount != 1:
                    print "Error: Dictionary contains multiple inflection index sections, which is not yet supported"
                    decodeInflection = False
                inflIndexData = sect.loadSection(metaInflIndex + 1)
                inflNameData = sect.loadSection(metaInflIndex + 1 + metaIndexCount)
                tagSectionStart, = struct.unpack_from('>L', metaInflIndexData, 0x04)
                inflectionControlByteCount, inflectionTagTable = readTagSection(tagSectionStart, metaInflIndexData)
                if DEBUG_DICT:
                    print "inflectionTagTable: %s" % inflectionTagTable
                if self.hasTag(inflectionTagTable, 0x07):
                    print "Error: Dictionary uses obsolete inflection rule scheme which is not yet supported"
                    decodeInflection = False

            data = sect.loadSection(metaOrthIndex)
            tagSectionStart, = struct.unpack_from('>L', data, 0x04)
            controlByteCount, tagTable = readTagSection(tagSectionStart, data)
            orthIndexCount, = struct.unpack_from('>L', data, 0x18)
            print "orthIndexCount is", orthIndexCount
            if DEBUG_DICT:
                print "orthTagTable: %s" % tagTable
            hasEntryLength = self.hasTag(tagTable, 0x02)
            if not hasEntryLength:
                print "Info: Index doesn't contain entry length tags"

            print "Read dictionary index data"
            for i in range(metaOrthIndex + 1, metaOrthIndex + 1 + orthIndexCount):
                data = sect.loadSection(i)
                idxtPos, = struct.unpack_from('>L', data, 0x14)
                entryCount, = struct.unpack_from('>L', data, 0x18)
                idxPositions = []
                for j in range(entryCount):
                    pos, = struct.unpack_from('>H', data, idxtPos + 4 + (2 * j))
                    idxPositions.append(pos)
                # The last entry ends before the IDXT tag (but there might be zero fill bytes we need to ignore!)
                idxPositions.append(idxtPos)

                for j in range(entryCount):
                    startPos = idxPositions[j]
                    endPos = idxPositions[j+1]
                    textLength = ord(data[startPos])
                    text = data[startPos+1:startPos+1+textLength]
                    tagMap = self.getTagMap(controlByteCount, tagTable, data, startPos+1+textLength, endPos)
                    if 0x01 in tagMap:
                        if decodeInflection and 0x2a in tagMap:
                            inflectionGroups = self.getInflectionGroups(text, inflectionControlByteCount, inflectionTagTable, inflIndexData, inflNameData, tagMap[0x2a])
                        else:
                            inflectionGroups = ""
                        assert len(tagMap[0x01]) == 1
                        entryStartPosition = tagMap[0x01][0]
                        if hasEntryLength:
                            # The idx:entry attribute "scriptable" must be present to create entry length tags.
                            ml = '<idx:entry scriptable="yes"><idx:orth value="%s">%s</idx:orth>' % (text, inflectionGroups)
                            if entryStartPosition in positionMap:
                                positionMap[entryStartPosition] = positionMap[entryStartPosition] + ml
                            else:
                                positionMap[entryStartPosition] = ml
                            assert len(tagMap[0x02]) == 1
                            entryEndPosition = entryStartPosition + tagMap[0x02][0]
                            if entryEndPosition in positionMap:
                                positionMap[entryEndPosition] = "</idx:entry>" + positionMap[entryEndPosition]
                            else:
                                positionMap[entryEndPosition] = "</idx:entry>"

                        else:
                            indexTags = '<idx:entry>\n<idx:orth value="%s">\n%s</idx:entry>\n' % (text, inflectionGroups)
                            if entryStartPosition in positionMap:
                                positionMap[entryStartPosition] = positionMap[entryStartPosition] + indexTags
                            else:
                                positionMap[entryStartPosition] = indexTags
        return positionMap

    def hasTag(self, tagTable, tag):
        '''
        Test if tag table contains given tag.

        @param tagTable: The tag table.
        @param tag: The tag to search.
        @return: True if tag table contains given tag; False otherwise.
        '''
        for currentTag, _, _, _ in tagTable:
            if currentTag == tag:
                return True
        return False

    def getInflectionGroups(self, mainEntry, controlByteCount, tagTable, data, inflectionNames, groupList):
        '''
        Create string which contains the inflection groups with inflection rules as mobipocket tags.

        @param mainEntry: The word to inflect.
        @param controlByteCount: The number of control bytes.
        @param tagTable: The tag table.
        @param data: The inflection index data.
        @param inflectionNames: The inflection rule name data.
        @param groupList: The list of inflection groups to process.
        @return: String with inflection groups and rules or empty string if required tags are not available.
        '''
        result = ""
        idxtPos, = struct.unpack_from('>L', data, 0x14)
        entryCount, = struct.unpack_from('>L', data, 0x18)
        for value in groupList:
            offset, = struct.unpack_from('>H', data, idxtPos + 4 + (2 * value))
            if value + 1 < entryCount:
                nextOffset, = struct.unpack_from('>H', data, idxtPos + 4 + (2 * (value + 1)))
            else:
                nextOffset = None

            # First byte seems to be always 0x00 and must be skipped.
            assert ord(data[offset]) == 0x00
            tagMap = self.getTagMap(controlByteCount, tagTable, data, offset + 1, nextOffset)

            # Make sure that the required tags are available.
            if 0x05 not in tagMap:
                print "Error: Required tag 0x05 not found in tagMap"
                return ""
            if 0x1a not in tagMap:
                print "Error: Required tag 0x1a not found in tagMap"
                return ""

            result += "<idx:infl>"

            for i in range(len(tagMap[0x05])):
                # Get name of inflection rule.
                value = tagMap[0x05][i]
                consumed, textLength = getVariableWidthValue(inflectionNames, value)
                inflectionName = inflectionNames[value+consumed:value+consumed+textLength]

                # Get and apply inflection rule.
                value = tagMap[0x1a][i]
                offset, = struct.unpack_from('>H', data, idxtPos + 4 + (2 * value))
                textLength = ord(data[offset])
                inflection = self.applyInflectionRule(mainEntry, data, offset+1, offset+1+textLength)
                if inflection != None:
                    result += '  <idx:iform name="%s" value="%s"/>' % (inflectionName, inflection)

            result += "</idx:infl>"
        return result

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
                    if DEBUG_DICT:
                        print "controlByteCount: %s" % controlByteCount
                        print "tagTable: %s" % tagTable
                        print "data: %s" % toHex(entryData[startPos:endPos])
                        print "tagHashMap: %s" % tagHashMap
                    break

        return tagHashMap

    def applyInflectionRule(self, mainEntry, inflectionRuleData, start, end):
        '''
        Apply inflection rule.

        @param mainEntry: The word to inflect.
        @param inflectionRuleData: The inflection rules.
        @param start: The start position of the inflection rule to use.
        @param end: The end position of the inflection rule to use.
        @return: The string with the inflected word or None if an error occurs.
        '''
        mode = -1
        byteArray = array.array("c", mainEntry)
        position = len(byteArray)
        for charOffset in range(start, end):
            char = inflectionRuleData[charOffset]
            byte = ord(char)
            if byte >= 0x0a and byte <= 0x13:
                # Move cursor backwards
                offset = byte - 0x0a
                if mode not in [0x02, 0x03]:
                    mode = 0x02
                    position = len(byteArray)
                position -= offset
            elif byte > 0x13:
                if mode == -1:
                    print "Error: Unexpected first byte %i of inflection rule" % byte
                    return None
                elif position == -1:
                    print "Error: Unexpected first byte %i of inflection rule" % byte
                    return None
                else:
                    if mode == 0x01:
                        # Insert at word start
                        byteArray.insert(position, char)
                        position += 1
                    elif mode == 0x02:
                        # Insert at word end
                        byteArray.insert(position, char)
                    elif mode == 0x03:
                        # Delete at word end
                        position -= 1
                        deleted = byteArray.pop(position)
                        if deleted != char:
                            if DEBUG_DICT:
                                print "0x03: %s %s %s %s" % (mainEntry, toHex(inflectionRuleData[start:end]), char, deleted)
                            print "Error: Delete operation of inflection rule failed"
                            return None
                    elif mode == 0x04:
                        # Delete at word start
                        deleted = byteArray.pop(position)
                        if deleted != char:
                            if DEBUG_DICT:
                                print "0x03: %s %s %s %s" % (mainEntry, toHex(inflectionRuleData[start:end]), char, deleted)
                            print "Error: Delete operation of inflection rule failed"
                            return None
                    else:
                        print "Error: Inflection rule mode %x is not implemented" % mode
                        return None
            elif byte == 0x01:
                # Insert at word start
                if mode not in [0x01, 0x04]:
                    position = 0
                mode = byte
            elif byte == 0x02:
                # Insert at word end
                if mode not in [0x02, 0x03]:
                    position = len(byteArray)
                mode = byte
            elif byte == 0x03:
                # Delete at word end
                if mode not in [0x02, 0x03]:
                    position = len(byteArray)
                mode = byte
            elif byte == 0x04:
                # Delete at word start
                if mode not in [0x01, 0x04]:
                    position = 0
                mode = byte
            else:
                print "Error: Inflection rule mode %x is not implemented" % byte
                return None
        return byteArray.tostring()

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
