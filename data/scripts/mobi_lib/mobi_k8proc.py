#!/usr/bin/env python
# vim:fileencoding=UTF-8:ts=4:sw=4:sta:et:sts=4:ai

import sys, struct, re
from mobi_index import MobiIndex
from mobi_utils import fromBase32

class K8Processor:
    def __init__(self, mh, sect, debug=False):
        self.sect = sect
        self.mi = MobiIndex(sect)
        self.mh = mh
        self.skelidx = mh.skelidx
        self.dividx = mh.dividx
        self.othidx = mh.othidx
        self.fdst = mh.fdst
        self.flowmap = {}
        self.flows = None
        self.flowinfo = []
        self.parts = None
        self.partinfo = []
        self.fdsttbl= [0,0xffffffff]
        self.DEBUG = debug

        # read in and parse the FDST info which is very similar in format to the Palm DB section
        # parsing except it provides offsets into rawML file and not the Palm DB file
        # this is needed to split up the final css, svg, etc flow section
        # that can exist at the end of the rawML file
        if self.fdst != 0xffffffff:
            header = self.sect.loadSection(self.fdst)
            if header[0:4] == "FDST":
                num_sections, = struct.unpack_from('>L', header, 0x08)
                sections = header[0x0c:]
                self.fdsttbl = struct.unpack_from('>%dL' % (num_sections*2), sections, 0)[::2] + (0xfffffff, )
            else:
                print "Error: K8 Mobi with Missing FDST info"
        if self.DEBUG:
            print "\nFDST Section Map:  %d entries" % len(self.fdsttbl)
            for j in xrange(len(self.fdsttbl)):
                print "  %d - %0x" % (j, self.fdsttbl[j])

        # read/process skeleton index info to create the skeleton table
        skeltbl = []
        if self.skelidx != 0xffffffff:
            outtbl, ctoc_text = self.mi.getIndexData(self.skelidx)
            fileptr = 0
            for [text, tagMap] in outtbl:
                # file number, skeleton name, divtbl record count, start position, length
                skeltbl.append([fileptr, text, tagMap[1][0], tagMap[6][0], tagMap[6][1]])
                fileptr += 1
        self.skeltbl = skeltbl
        if self.DEBUG:
            print "\nSkel Table:  %d entries" % len(self.skeltbl)
            print "table: filenum, skeleton name, div tbl record count, start position, length"
            for j in xrange(len(self.skeltbl)):
                print self.skeltbl[j]

        # read/process the div index to create to <div> (and <p>) table
        divtbl = []
        if self.dividx != 0xffffffff:
            outtbl, ctoc_text = self.mi.getIndexData(self.dividx)
            for [text, tagMap] in outtbl:
                # insert position, ctoc offset (aidtext), file number, sequence number, start position, length
                ctocoffset = tagMap[2][0]
                ctocdata = ctoc_text[ctocoffset]
                divtbl.append([int(text), ctocdata, tagMap[3][0], tagMap[4][0], tagMap[6][0], tagMap[6][1]])
        self.divtbl = divtbl
        if self.DEBUG:
            print "\nDiv (Fragment) Table: %d entries" % len(self.divtbl)
            print "table: file position, link id text, file num, sequence number, start position, length"
            for j in xrange(len(self.divtbl)):
                print self.divtbl[j]

        # read / process other index <guide> element of opf
        othtbl = []
        if self.othidx != 0xffffffff:
            outtbl, ctoc_text = self.mi.getIndexData(self.othidx)
            for [text, tagMap] in outtbl:
                # ref_type, ref_title, div/frag number
                ctocoffset = tagMap[1][0]
                ref_title = ctoc_text[ctocoffset]
                ref_type = text
                fileno = None
                if 3 in tagMap.keys():
                    fileno  = tagMap[3][0]
                if 6 in tagMap.keys():
                    fileno = tagMap[6][0]
                othtbl.append([ref_type, ref_title, fileno])
        self.othtbl = othtbl
        if self.DEBUG:
            print "\nOther (Guide) Table: %d entries" % len(self.othtbl)
            print "table: ref_type, ref_title, divtbl entry number"
            for j in xrange(len(self.othtbl)):
                print self.othtbl[j]


    def buildParts(self, rawML):
        # now split the rawML into its flow pieces
        self.flows = []
        for j in xrange(0, len(self.fdsttbl)-1):
            start = self.fdsttbl[j]
            end = self.fdsttbl[j+1]
            if end == 0xffffffff:
                end = len(rawML)
                if self.DEBUG:
                    print "splitting rawml starting at %d and ending at %d into flow piece %d" % (start, end, j)
            self.flows.append(rawML[start:end])

        # the first piece represents the xhtml text
        text = self.flows[0]
        self.flows[0] = ''

        # walk the <skeleton> and <div> tables to build original source xhtml files
        # *without* destroying any file position information needed for later href processing
        # and create final list of file separation start: stop points and etc in partinfo
        if self.DEBUG:
            print "\nRebuilding flow piece 0: the main body of the ebook"
        self.parts = []
        self.partinfo = []
        divptr = 0
        baseptr = 0
        for [skelnum, skelname, divcnt, skelpos, skellen] in self.skeltbl:
            baseptr = skelpos + skellen
            skeleton = text[skelpos: baseptr]
            for i in range(divcnt):
                [insertpos, idtext, filenum, seqnum, startpos, length] = self.divtbl[divptr]
                if self.DEBUG:
                    print "    moving div/frag %d starting at %d of length %d" % (divptr, startpos, length)
                    print "        inside of skeleton number %d at postion %d" %  (skelnum, insertpos)
                if i == 0:
                    aidtext = idtext[12:-2]
                    filename = 'part%04d.xhtml' % filenum
                slice = text[baseptr: baseptr + length]
                insertpos = insertpos - skelpos
                skeleton = skeleton[0:insertpos] + slice + skeleton[insertpos:]
                baseptr = baseptr + length
                divptr += 1
            self.parts.append(skeleton)
            self.partinfo.append([skelnum, 'Text', filename, skelpos, baseptr, aidtext])

        # The primary css style sheet is typically stored next followed by any
        # snippets of code that were previously inlined in the
        # original xhtml but have been stripped out and placed here.
        # This can include local CDATA snippets and and svg sections.

        # The problem is that for most browsers and ereaders, you can not
        # use <img src="imageXXXX.svg" /> to import any svg image that itself
        # properly uses an <image/> tag to import some raster image - it
        # should work according to the spec but does not for almost all browsers
        # and ereaders and causes epub validation issues because those  raster
        # images are in manifest but not in xhtml text - since they only
        # referenced from an svg image

        # So we need to check the remaining flow pieces to see if they are css
        # or svg images.  if svg images, we must check if they have an <image />
        # and if so inline them into the xhtml text pieces.

        # there may be other sorts of pieces stored here but until we see one
        # in the wild to reverse engineer we won't be able to tell
        self.flowinfo.append([None, None, None, None])
        svg_tag_pattern = re.compile(r'''(<svg[^>]*>)''', re.IGNORECASE)
        image_tag_pattern = re.compile(r'''(<image[^>]*>)''', re.IGNORECASE)
        for j in xrange(1,len(self.flows)):
            flowpart = self.flows[j]
            nstr = '%04d' % j
            m = re.search(svg_tag_pattern, flowpart)
            if m != None:
                # svg
                type = 'svg'
                start = m.start()
                m2 = re.search(image_tag_pattern, flowpart)
                if m2 != None:
                    format = 'inline'
                    dir = None
                    fname = None
                    # strip off anything before <svg if inlining
                    flowpart = flowpart[start:]
                else:
                    format = 'file'
                    dir = "Images"
                    fname = 'svgimg' + nstr + '.svg'
            else:
                # search for CDATA and if exists inline it
                if flowpart.find('[CDATA[') >= 0:
                    type = 'css'
                    flowpart = '<style type="text/css">\n' + flowpart + '\n</style>\n'
                    format = 'inline'
                    dir = None
                    fname = None
                else:
                    # css - assume as standalone css file
                    type = 'css'
                    format = 'file'
                    dir = "Styles"
                    fname = 'style' + nstr + '.css'

            self.flows[j] = flowpart
            self.flowinfo.append([type, format, dir, fname])
        
        if self.DEBUG:
            print "\nFlow Map:  %d entries" % len(self.flowinfo)
            for fi in self.flowinfo:
                print fi
            print "\n"

            print "\nXHTML File Part Position Information: %d entries" % len(self.partinfo)
            for pi in self.partinfo:
                print pi

        if False:  # self.DEBUG:
            # dump all of the locations of the aid tags used in TEXT
            # find id links only inside of tags
            #    inside any < > pair find all "aid=' and return whatever is inside the quotes
            #    [^>]* means match any amount of chars except for  '>' char
            #    [^'"] match any amount of chars except for the quote character
            #    \s* means match any amount of whitespace
            print "\npositions of all aid= pieces"
            id_pattern = re.compile(r'''<[^>]*\said\s*=\s*['"]([^'"]*)['"][^>]*>''',re.IGNORECASE)
            for m in re.finditer(id_pattern, rawML):
                print "%0x %s %0x" % (m.start(), m.group(1), fromBase32(m.group(1)))
                [filename, partnum, start, end] = self.getFileInfo(m.start())
                print "   in  %d %0x %0x" % (partnum, start, end)

        return

    # get information about the part (file) that exists at pos in oriignal rawML
    def getFileInfo(self, pos):
        for [partnum, dir, filename, start, end, aidtext] in self.partinfo:
            if pos >= start and pos < end:
                return filename, partnum, start, end
        return None, None, None, None


    # accessor functions to properly protect the internal structure
    def getNumberOfParts(self):
        return len(self.parts)

    def getPart(self,i):
        if i >= 0 and i < len(self.parts):
            return self.parts[i]
        return None

    def getPartInfo(self, i):
        if i >= 0 and i < len(self.partinfo):
            return self.partinfo[i]
        return None

    def getNumberOfFlows(self):
        return len(self.flows)

    def getFlow(self,i):
        # note flows[0] is empty - it was all of the original text
        if i > 0 and i < len(self.flows):
            return self.flows[i]
        return None

    def getFlowInfo(self,i):
        # note flowinfo[0] is empty - it was all of the original text
        if i > 0 and i < len(self.flowinfo):
            return self.flowinfo[i]
        return None


    def getIDTagByPosFid(self, posfid, offset):
        # first convert kindle:pos:fid and offset info to position in file
        row = fromBase32(posfid)
        off = fromBase32(offset)
        [insertpos, idtext, filenum, seqnm, startpos, length] = self.divtbl[row]
        pos = insertpos + off
        fname, pn, skelpos, skelend = self.getFileInfo(pos)
        # an existing "id=" must exist in original xhtml otherwise it would not have worked for linking.
        # Amazon seems to have added its own additional "aid=" inside tags whose contents seem to represent
        # some position information encoded into Base32 name.

        # so find the closest "id=" before position the file  by actually searching in that file
        idtext = self.getIDTag(pos)
        return fname, idtext

    def getIDTag(self, pos):
        # find the correct tag by actually searching in the destination textblock at position
        fname, pn, skelpos, skelend = self.getFileInfo(pos)
        textblock = self.parts[pn]
        idtbl = []
        npos = pos - skelpos
        pgt = textblock.find('>',npos)
        plt = textblock.find('<',npos)
        # if npos inside a tag then search all text before the its end of tag marker
        # else not in a tag need to search the preceding tag
        if plt == npos  or  pgt < plt:
            npos = pgt + 1
        textblock = textblock[0:npos]
        # find id links only inside of tags
        #    inside any < > pair find all "id=' and return whatever is inside the quotes
        #    [^>]* means match any amount of chars except for  '>' char
        #    [^'"] match any amount of chars except for the quote character
        #    \s* means match any amount of whitespace
        id_pattern = re.compile(r'''<[^>]*\sid\s*=\s*['"]([^'"]*)['"][^>]*>''',re.IGNORECASE)
        for m in re.finditer(id_pattern, textblock):
            idtbl.append([m.start(), m.group(1)])
        n = len(idtbl)
        if n == 0:
            if self.DEBUG:
                print "Found no id in the textblock, link must be to top of file"
            return ''
        # if npos is before first id= inside a tag, return the first
        if npos < idtbl[0][0] :
            return idtbl[0][1]
        # if npos is after the last id= inside a tag, return the last
        if npos > idtbl[n-1][0] :
            return idtbl[n-1][1]
        # otherwise find last id before npos
        tgt = 0
        for r in xrange(n):
            if npos < idtbl[r][0]:
                tgt = r-1
                break
        if self.DEBUG:
            print pos, npos, idtbl[tgt]
        return idtbl[tgt][1]


    # do we need to do deep copying
    def setParts(self, parts):
        assert(len(parts) == len(self.parts))
        for i in range(len(parts)):
            self.parts[i] = parts[i]

    # do we need to do deep copying
    def setFlows(self, flows):
        assert(len(flows) == len(self.flows))
        for i in xrange(len(flows)):
            self.flows[i] = flows[i]


    # get information about the part (file) that exists at pos in oriignal rawML
    def getSkelInfo(self, pos):
        for [partnum, dir, filename, start, end, aidtext] in self.partinfo:
            if pos >= start and pos < end:
                return [partnum, dir, filename, start, end, aidtext]
        return [None, None, None, None, None, None]

    # fileno is actually a reference into divtbl (a fragment)
    def getGuideText(self):
        guidetext = ''
        for [ref_type, ref_title, fileno] in self.othtbl:
            [pos, idtext, filenum, seqnm, startpos, length] = self.divtbl[fileno]
            [pn, dir, filename, skelpos, skelend, aidtext] = self.getSkelInfo(pos)
            idtext = self.getIDTag(pos)
            linktgt = filename
            if idtext != '':
                linktgt += '#' + idtext
            guidetext += '<reference type="%s" title="%s" href="%s/%s" />\n' % (ref_type, ref_title, dir, linktgt)
        # opf is encoded utf-8 so must convert any titles properly
        guidetext = unicode(guidetext, self.mh.codec).encode("utf-8")
        return guidetext
