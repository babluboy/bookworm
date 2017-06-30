#!/usr/bin/env python
# vim:fileencoding=UTF-8:ts=4:sw=4:sta:et:sts=4:ai

# Changelog
#  0.11 - Version by adamselene
#  0.11pd - Tweaked version by pdurrant
#  0.12 - extracts pictures too, and all into a folder.
#  0.13 - added back in optional output dir for those who don't want it based on infile
#  0.14 - auto flush stdout and wrapped in main, added proper return codes
#  0.15 - added support for metadata
#  0.16 - metadata now starting to be output as an opf file (PD)
#  0.17 - Also created tweaked text as source for Mobipocket Creator
#  0.18 - removed raw mobi file completely but kept _meta.html file for ease of conversion
#  0.19 - added in metadata for ASIN, Updated Title and Rights to the opf
#  0.20 - remove _meta.html since no longer needed
#  0.21 - Fixed some typos in the opf output, and also updated handling
#         of test for trailing data/multibyte characters
#  0.22 - Fixed problem with > 9 images
#  0.23 - Now output Start guide item
#  0.24 - Set firstaddl value for 'TEXtREAd'
#  0.25 - Now added character set metadata to html file for utf-8 files.
#  0.26 - Dictionary support added. Image handling speed improved. 
#         For huge files create temp files to speed up decoding.
#         Language decoding fixed. Metadata is now converted to utf-8 when written to opf file.
#  0.27 - Add idx:entry attribute "scriptable" if dictionary contains entry length tags. 
#         Don't save non-image sections as images. Extract and save source zip file 
#         included by kindlegen as kindlegensrc.zip.
#  0.28 - Added back correct image file name extensions, created FastConcat class to simplify and clean up
#  0.29 - Metadata handling reworked, multiple entries of the same type are now supported. 
#         Several missing types added.
#         FastConcat class has been removed as in-memory handling with lists is faster, even for huge files.
#  0.30 - Add support for outputting **all** metadata values - encode content with hex if of unknown type
#  0.31 - Now supports Print Replica ebooks, outputting PDF and mysterious data sections
#  0.32 - Now supports NCX file extraction/building.
#                 Overhauled the structure of mobiunpack to be more class oriented.
#  0.33 - Split Classes ito separate files and added prelim support for KF8 format eBooks
#  0.34 - Improved KF8 support, guide support, bug fixes
#  0.35 - Added splitting combo mobi7/mobi8 into standalone mobi7 and mobi8 files
#         Also handle mobi8-only file properly
#  0.36 - very minor changes to support KF8 mobis with no flow items, no ncx, etc
#  0.37 - separate output, add command line switches to control, interface to Mobi_Unpack.pyw
#  0.38 - improve split function by resetting flags properly, fix bug in Thumbnail Images
#  0.39 - improve split function so that ToC info is not lost for standalone mobi8s
#  0.40 - make mobi7 split match official versions, add support for graphic novel metadata, 
#         improve debug for KF8
#  0.41 - fix when StartOffset set to 0xffffffff, fix to work with older mobi versions, 
#         fix other minor metadata issues
#  0.42 - add new class interface to allow it to integrate more easily with internal calibre routines
#  0.43 - bug fixes for new class interface
#  0.44 - more bug fixes and fix for potnetial bug caused by not properly closing created zip archive
#  0.45 - sync to version in the new Mobi_Unpack plugin
#  0.46 - fixes for: obfuscated fonts, improper toc links and ncx, add support for opentype fonts
#  0.47 - minor opf improvements
 
DEBUG = False
""" Set to True to print debug information. """

WRITE_RAW_DATA = False
""" Set to True to create additional files with raw data for debugging/reverse engineering. """

SPLIT_COMBO_MOBIS = False
""" Set to True to split combination mobis into mobi7 and mobi8 pieces. """

EOF_RECORD = chr(0xe9) + chr(0x8e) + "\r\n"
""" The EOF record content. """

KINDLEGENSRC_FILENAME = "kindlegensrc.zip"
""" The name for the kindlegen source archive. """

K8_BOUNDARY = "BOUNDARY"
""" The section data that divides K8 mobi ebooks. """

class Unbuffered:
    def __init__(self, stream):
        self.stream = stream
    def write(self, data):
        self.stream.write(data)
        self.stream.flush()
    def __getattr__(self, attr):
        return getattr(self.stream, attr)
import sys
sys.stdout=Unbuffered(sys.stdout)

import array, struct, os, re, imghdr, zlib, zipfile
import getopt, binascii

# import the mobiunpack support libraries
from mobi_utils import getLanguage, toHex, fromBase32, toBase32, read_zlib_header, mangle_fonts
from mobi_uncompress import HuffcdicReader, PalmdocReader, UncompressedReader
from mobi_opf import OPFProcessor
from mobi_html import HTMLProcessor, XHTMLK8Processor
from mobi_ncx import ncxExtract
from mobi_dict import dictSupport
from mobi_k8proc import K8Processor
from mobi_split import mobi_split

class unpackException(Exception):
    pass

class ZipInfo(zipfile.ZipInfo):
    def __init__(self, *args, **kwargs):
        if 'compress_type' in kwargs:
            compress_type = kwargs.pop('compress_type')
        super(ZipInfo, self).__init__(*args, **kwargs)
        self.compress_type = compress_type

class fileNames:
    def __init__(self, infile, outdir):
        self.infile = infile
        self.outdir = outdir
        if not os.path.exists(outdir):
            os.mkdir(outdir)
        self.mobi7dir = os.path.join(outdir,'mobi7')
        if not os.path.exists(self.mobi7dir):
            os.mkdir(self.mobi7dir)

        self.imgdir = os.path.join(self.mobi7dir, 'images')
        if not os.path.exists(self.imgdir):
            os.mkdir(self.imgdir)
        self.outbase = os.path.join(outdir, os.path.splitext(os.path.split(infile)[1])[0])

    def getInputFileBasename(self):
        return os.path.splitext(os.path.basename(self.infile))[0]

    def makeK8Struct(self):
        outdir = self.outdir
        self.k8dir = os.path.join(self.outdir,'mobi8')
        if not os.path.exists(self.k8dir):
            os.mkdir(self.k8dir)
        self.k8metainf = os.path.join(self.k8dir,'META-INF')
        if not os.path.exists(self.k8metainf):
            os.mkdir(self.k8metainf)
        self.k8oebps = os.path.join(self.k8dir,'OEBPS')
        if not os.path.exists(self.k8oebps):
            os.mkdir(self.k8oebps)
        self.k8images = os.path.join(self.k8oebps,'Images')
        if not os.path.exists(self.k8images):
            os.mkdir(self.k8images)
        self.k8fonts = os.path.join(self.k8oebps,'Fonts')
        if not os.path.exists(self.k8fonts):
            os.mkdir(self.k8fonts)
        self.k8styles = os.path.join(self.k8oebps,'Styles')
        if not os.path.exists(self.k8styles):
            os.mkdir(self.k8styles)
        self.k8text = os.path.join(self.k8oebps,'Text')
        if not os.path.exists(self.k8text):
            os.mkdir(self.k8text)

    # recursive zip creation support routine
    def zipUpDir(self, myzip, tdir, localname):
        currentdir = tdir
        if localname != "":
            currentdir = os.path.join(currentdir,localname)
        list = os.listdir(currentdir)
        for file in list:
            afilename = file
            localfilePath = os.path.join(localname, afilename)
            realfilePath = os.path.join(currentdir,file)
            if os.path.isfile(realfilePath):
                myzip.write(realfilePath, localfilePath, zipfile.ZIP_DEFLATED)
            elif os.path.isdir(realfilePath):
                self.zipUpDir(myzip, tdir, localfilePath)

    def makeEPUB(self, usedmap, obfuscate_data, uid):
        bname = os.path.join(self.k8dir, self.getInputFileBasename() + '.epub')

        # Create an encryption key for Adobe font obfuscation
        # based on the epub's uid
        if obfuscate_data:
            key = re.sub(r'[^a-fA-F0-9]', '', uid)
            key = binascii.unhexlify((key + key)[:32])

        # copy over all images and fonts that are actually used in the ebook
        # and remove all font files from mobi7 since not supported
        imgnames = os.listdir(self.imgdir)
        for name in imgnames:
            if usedmap.get(name,'not used') == 'used':
                filein = os.path.join(self.imgdir,name)
                if name.endswith(".ttf"):
                    fileout = os.path.join(self.k8fonts,name)
                elif name.endswith(".otf"):
                    fileout = os.path.join(self.k8fonts,name)
                else:
                    fileout = os.path.join(self.k8images,name)
                data = file(filein,'rb').read()
                if obfuscate_data:
                    if name in obfuscate_data:
                        data = mangle_fonts(key, data)
                file(fileout,'wb').write(data)
                if name.endswith(".ttf") or name.endswith(".otf"):
                    os.remove(filein)

        # opf file name hard coded to "content.opf"
        container = '<?xml version="1.0" encoding="UTF-8"?>\n'
        container += '<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">\n'
        container += '    <rootfiles>\n'
        container += '<rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>'
        container += '    </rootfiles>\n</container>\n'
        fileout = os.path.join(self.k8metainf,'container.xml')
        file(fileout,'wb').write(container)
        
        if obfuscate_data:
            encryption = '<encryption xmlns="urn:oasis:names:tc:opendocument:xmlns:container" \
xmlns:enc="http://www.w3.org/2001/04/xmlenc#" xmlns:deenc="http://ns.adobe.com/digitaleditions/enc">\n'
            for font in obfuscate_data:
                encryption += '  <enc:EncryptedData>\n'
                encryption += '    <enc:EncryptionMethod Algorithm="http://ns.adobe.com/pdf/enc#RC"/>\n'
                encryption += '    <enc:CipherData>\n'
                encryption += '      <enc:CipherReference URI="OEBPS/Fonts/' + font + '"/>\n'
                encryption += '    </enc:CipherData>\n'
                encryption += '  </enc:EncryptedData>\n'
            encryption += '</encryption>\n'
            fileout = os.path.join(self.k8metainf,'encryption.xml')
            file(fileout,'wb').write(encryption)

        # ready to build epub
        self.outzip = zipfile.ZipFile(bname, 'w')

        # add the mimetype file uncompressed
        mimetype = 'application/epub+zip'
        fileout = os.path.join(self.k8dir,'mimetype')
        file(fileout,'wb').write(mimetype)
        nzinfo = ZipInfo('mimetype', compress_type=zipfile.ZIP_STORED)
        self.outzip.writestr(nzinfo, mimetype)

        self.zipUpDir(self.outzip,self.k8dir,'META-INF')

        self.zipUpDir(self.outzip,self.k8dir,'OEBPS')
        self.outzip.close()



class Sectionizer:
    def __init__(self, filename_or_stream):
        if hasattr(filename_or_stream, 'read'):
            self.stream = filename_or_stream
            self.stream.seek(0)
        else:
            self.stream = open(filename_or_stream, 'rb')
        header = self.stream.read(78)
        self.ident = header[0x3C:0x3C+8]
        self.num_sections, = struct.unpack_from('>H', header, 76)
        sections = self.stream.read(self.num_sections*8)
        self.sections = struct.unpack_from('>%dL' % (self.num_sections*2), sections, 0)[::2] + (0xfffffff, )

    def loadSection(self, section):
        before, after = self.sections[section:section+2]
        self.stream.seek(before)
        return self.stream.read(after - before)


class MobiHeader:
    def __init__(self, sect, sectNumber):
        self.sect = sect
        self.start = sectNumber
        self.header = self.sect.loadSection(self.start)
        self.records, = struct.unpack_from('>H', self.header, 0x8)
        self.length, self.type, self.codepage, self.unique_id, self.version = struct.unpack('>LLLLL', self.header[20:40])
        print "Mobi Version: ", self.version

        # codec
        self.codec = 'windows-1252'
        codec_map = {
            1252 : 'windows-1252',
            65001: 'utf-8',
        }
        if self.codepage in codec_map.keys():
            self.codec = codec_map[self.codepage]
        print "Codec: ", self.codec

        # title
        toff, tlen = struct.unpack('>II', self.header[0x54:0x5c])
        tend = toff + tlen
        self.title=self.header[toff:tend]
        print "Title: ", self.title

        # set up for decompression/unpacking
        compression, = struct.unpack_from('>H', self.header, 0x0)
        if compression == 0x4448:
            print "Huffdic compression"
            reader = HuffcdicReader()
            huffoff, huffnum = struct.unpack_from('>LL', self.header, 0x70)
            huffoff = huffoff + self.start
            reader.loadHuff(self.sect.loadSection(huffoff))
            for i in xrange(1, huffnum):
                reader.loadCdic(self.sect.loadSection(huffoff+i))
            self.unpack = reader.unpack
        elif compression == 2:
            print "Palmdoc compression"
            self.unpack = PalmdocReader().unpack
        elif compression == 1:
            print "No compression"
            self.unpack = UncompressedReader().unpack
        else:
            raise unpackException('invalid compression type: 0x%4x' % compression)

        exth_flag, = struct.unpack('>L', self.header[0x80:0x84])
        self.hasExth = exth_flag & 0x40
        self.mlstart = self.sect.loadSection(self.start+1)
        self.mlstart = self.mlstart[0:4]
        self.crypto_type, = struct.unpack_from('>H', self.header, 0xC)

        # default initial values set to disable these advanced features not found in TEXtREAd
        self.firstaddl = self.records + 1
        self.ncxidx = 0xffffffff
        self.metaOrthIndex = 0xffffffff
        self.metaInflIndex = 0xffffffff
        self.skelidx = 0xffffffff
        self.dividx = 0xffffffff
        self.othidx = 0xfffffff
        self.fdst = 0xffffffff

        if self.sect.ident == 'TEXtREAd':
            return

        # Start sector for additional files such as images, fonts, resources, etc
        self.firstaddl, = struct.unpack_from('>L', self.header, 0x6C)
        if self.firstaddl != 0xffffffff:
            self.firstaddl += self.start

        if self.mlstart == '%MOP':
            return

        if self.version < 8:
            # Dictionary metaOrthIndex
            self.metaOrthIndex, = struct.unpack_from('>L', self.header, 0x28)
            if self.metaOrthIndex != 0xffffffff:
                self.metaOrthIndex += self.start

            # Dictionary metaInflIndex
            self.metaInflIndex, = struct.unpack_from('>L', self.header, 0x2C)
            if self.metaInflIndex != 0xffffffff:
                self.metaInflIndex += self.start

        # handle older headers without any ncxindex info and later
        # specifically 0xe4 headers
        if self.length + 16 < 0xf8:
            return

        # NCX Index
        self.ncxidx, = struct.unpack('>L', self.header[0xf4:0xf8])
        if self.ncxidx != 0xffffffff:
            self.ncxidx += self.start

        # K8 specific Indexes
        if self.start != 0 or self.version == 8:
            # Index into <xml> file skeletons in RawML
            self.skelidx, = struct.unpack_from('>L', self.header, 0xfc)
            if self.skelidx != 0xffffffff:
                self.skelidx += self.start

            # Index into <div> sections in RawML
            self.dividx, = struct.unpack_from('>L', self.header, 0xf8)
            if self.dividx != 0xffffffff:
                self.dividx += self.start

            # Index into Other files
            self.othidx, = struct.unpack_from('>L', self.header, 0x104)
            if self.othidx != 0xffffffff:
                self.othidx += self.start

            # dictionaries do not seem to use the same approach in K8's
            # so disable them
            self.metaOrthIndex = 0xffffffff
            self.metaInflIndex = 0xffffffff

            # need to use the FDST record to find out how to properly unpack
            # the rawML into pieces
            # it is simply a table of start and end locations for each flow piece
            self.fdst, = struct.unpack_from('>L', self.header, 0xc0)
            self.fdstcnt, = struct.unpack_from('>L', self.header, 0xc4)
            # if cnt is 1 or less, fdst section mumber can be garbage
            if self.fdstcnt <= 1:
                self.fdst = 0xffffffff
            if self.fdst != 0xffffffff:
                self.fdst += self.start

        if DEBUG:
            print "firstaddl %0x" % self.firstaddl
            print "ncxidx %0x" % self.ncxidx
            print "exth flags %0x" % exth_flag
            if self.version == 8 or self.start != 0:
                print "skelidx %0x" % self.skelidx
                print "dividx %0x" % self.dividx
                print "othidx %0x" % self.othidx
                print "fdst %0x" % self.fdst

        # NOTE: See DumpMobiHeader.py for a complete set of header fields

    def isPrintReplica(self):
        return self.mlstart[0:4] == "%MOP"

    def isK8(self):
        return self.start != 0 or self.version == 8

    def isEncrypted(self):
        return self.crypto_type != 0

    def hasNCX(self):
        return self.ncxidx != 0xffffffff

    def isDictionary(self):
        return self.metaOrthIndex != 0xffffffff

    def getfirstAddl(self):
        return self.firstaddl

    def getncxIndex(self):
        return self.ncxidx

    def decompress(self, data):
        return self.unpack(data)

    def Language(self):
        langcode = struct.unpack('!L', self.header[0x5c:0x60])[0]
        langid = langcode & 0xFF
        sublangid = (langcode >> 10) & 0xFF
        return [getLanguage(langid, sublangid)]

    def DictInLanguage(self):
        if self.isDictionary():
            langcode = struct.unpack('!L', self.header[0x60:0x64])[0]
            langid = langcode & 0xFF
            sublangid = (langcode >> 10) & 0xFF
            if langid != 0:
                return [getLanguage(langid, sublangid)]
        return False

    def DictOutLanguage(self):
        if self.isDictionary():
            langcode = struct.unpack('!L', self.header[0x64:0x68])[0]
            langid = langcode & 0xFF
            sublangid = (langcode >> 10) & 0xFF
            if langid != 0:
                return [getLanguage(langid, sublangid)]
        return False

    def getRawML(self):
        def getSizeOfTrailingDataEntry(data):
            num = 0
            for v in data[-4:]:
                if ord(v) & 0x80:
                    num = 0
                num = (num << 7) | (ord(v) & 0x7f)
            return num
        def trimTrailingDataEntries(data):
            for _ in xrange(trailers):
                num = getSizeOfTrailingDataEntry(data)
                data = data[:-num]
            if multibyte:
                num = (ord(data[-1]) & 3) + 1
                data = data[:-num]
            return data
        multibyte = 0
        trailers = 0
        if self.sect.ident == 'BOOKMOBI':
            mobi_length, = struct.unpack_from('>L', self.header, 0x14)
            mobi_version, = struct.unpack_from('>L', self.header, 0x68)
            if (mobi_length >= 0xE4) and (mobi_version >= 5):
                flags, = struct.unpack_from('>H', self.header, 0xF2)
                multibyte = flags & 1
                while flags > 1:
                    if flags & 2:
                        trailers += 1
                    flags = flags >> 1
        # get raw mobi markup languge
        print "Unpack raw markup language"
        dataList = []
        # offset = 0
        for i in xrange(1, self.records+1):
            data = trimTrailingDataEntries(self.sect.loadSection(self.start + i))
            dataList.append(self.unpack(data))
        return "".join(dataList)

    def getMetaData(self):
        codec=self.codec
        metadata = {}
        if not self.hasExth:
            return metadata

        extheader=self.header[16 + self.length:]
        id_map_strings = {
                  1 : 'Drm Server Id',
                  2 : 'Drm Commerce Id',
                  3 : 'Drm Ebookbase Book Id',
                100 : 'Creator',
                101 : 'Publisher',
                102 : 'Imprint',
                103 : 'Description',
                104 : 'ISBN',
                105 : 'Subject',
                106 : 'Published',
                107 : 'Review',
                108 : 'Contributor',
                109 : 'Rights',
                110 : 'SubjectCode',
                111 : 'Type',
                112 : 'Source',
                113 : 'ASIN',
                114 : 'versionNumber',
                117 : 'Adult',
                118 : 'Price',
                119 : 'Currency',
                122 : 'fixed-layout',
                123 : 'book-type',
                124 : 'orientation-lock',
                126 : 'original-resolution',
                127 : 'zero-gutter',
                128 : 'zero-margin',
                129 : 'K8(129)_Masthead/Cover_Image',
                132 : 'RegionMagnification',
                200 : 'DictShortName',
                208 : 'Watermark',
                501 : 'CDE Type',
                502 : 'last_update_time',
                503 : 'Updated Title',
        }
        id_map_values = {
                115 : 'sample',
                116 : 'StartOffset',
                121 : 'K8(121)_Boundary_Section',
                125 : 'K8(125)_Count_of_Resources_Fonts_Images',
                131 : 'K8(131)_Unidentified_Count',
                201 : 'CoverOffset',
                202 : 'ThumbOffset',
                203 : 'Fake Cover',
                204 : 'Creator Software',
                205 : 'Creator Major Version',
                206 : 'Creator Minor Version',
                207 : 'Creator Build Number',
                401 : 'Clipping Limit',
                402 : 'Publisher Limit',
                404 : 'Text to Speech Disabled',
        }
        id_map_hexstrings = {
                209 : 'Tamper Proof Keys (hex)',
                300 : 'Font Signature (hex)',
        }
        def addValue(name, value):
            if name not in metadata:
                metadata[name] = [value]
            else:
                metadata[name].append(value)
                if DEBUG:
                    print "multiple values: metadata[%s]=%s" % (name, metadata[name])
        _length, num_items = struct.unpack('>LL', extheader[4:12])
        extheader = extheader[12:]
        pos = 0
        for _ in range(num_items):
            id, size = struct.unpack('>LL', extheader[pos:pos+8])
            content = extheader[pos + 8: pos + size]
            if id in id_map_strings.keys():
                name = id_map_strings[id]
                addValue(name, unicode(content, codec).encode("utf-8"))
            elif id in id_map_values.keys():
                name = id_map_values[id]
                if size == 9:
                    value, = struct.unpack('B',content)
                    addValue(name, str(value))
                elif size == 10:
                    value, = struct.unpack('>H',content)
                    addValue(name, str(value))
                elif size == 12:
                    value, = struct.unpack('>L',content)
                    addValue(name, str(value))
                else:
                    print "Error: Value for %s has unexpected size of %s" % (name, size)
            elif id in id_map_hexstrings.keys():
                name = id_map_hexstrings[id]
                addValue(name, content.encode('hex'))
            else:
                print "Warning: Unknown metadata with id %s found" % id
                name = str(id) + ' (hex)'
                addValue(name, content.encode('hex'))
            pos += size
        return metadata

    def processPrintReplica(self, files):
        # read in number of tables, and so calculate the start of the indicies into the data
        rawML = self.getRawML()
        numTables, = struct.unpack_from('>L', rawML, 0x04)
        tableIndexOffset = 8 + 4*numTables
        # for each table, read in count of sections, assume first section is a PDF
        # and output other sections as binary files
        paths = []
        for i in xrange(numTables):
            sectionCount, = struct.unpack_from('>L', rawML, 0x08 + 4*i)
            for j in xrange(sectionCount):
                sectionOffset, sectionLength, = struct.unpack_from('>LL', rawML, tableIndexOffset)
                tableIndexOffset += 8
                if j == 0:
                    entryName = os.path.join(files.outdir, files.getInputFileBasename() + ('.%03d.pdf' % (i+1)))
                else:
                    entryName = os.path.join(files.outdir, files.getInputFileBasename() + ('.%03d.%03d.data' % ((i+1),j)))
                file(entryName, 'wb').write(rawML[sectionOffset:(sectionOffset+sectionLength)])


def process_all_mobi_headers(files, sect, mhlst, K8Boundary, k8only=False):
    imgnames = []
    for mh in mhlst:

        if mh.isK8():
            print "\n\nProcessing K8 format Ebook ..."
        elif mh.isPrintReplica():
            print "\nProcessing PrintReplica (.azw4) format Ebook ..."
        else:
            print "\nProcessing Mobi format Ebook ..."

        if DEBUG:
            # write out raw mobi header data
            mhname = os.path.join(files.outdir,"header.dat")
            if mh.isK8():
                mhname = os.path.join(files.outdir,"header_K8.dat")
            file(mhname, 'wb').write(mh.header)

        # process each mobi header
        if mh.isEncrypted():
            raise unpackException('file is encrypted')

        # build up the metadata
        metadata = mh.getMetaData()
        metadata['Language'] = mh.Language()
        metadata['Title'] = [unicode(mh.title, mh.codec).encode("utf-8")]
        metadata['Codec'] = [mh.codec]
        metadata['UniqueID'] = [str(mh.unique_id)]
        if DEBUG:
            print "MetaData from EXTH"
            print metadata

        # save the raw markup language
        rawML = mh.getRawML()
        if DEBUG or WRITE_RAW_DATA:
            ext = '.rawml'
            if mh.isK8():
                outraw = os.path.join(files.k8dir,files.getInputFileBasename() + ext)
            else:
                if mh.isPrintReplica():
                    ext = '.rawpr'
                    outraw = os.path.join(files.outdir,files.getInputFileBasename() + ext)
                else:
                    outraw = os.path.join(files.mobi7dir,files.getInputFileBasename() + ext)
            file(outraw,'wb').write(rawML)

        # process additional sections that represent images, resources, fonts, and etc
        # build up a list of image names to use to postprocess the rawml
        print "Unpacking images, resources, fonts, etc"
        firstaddl = mh.getfirstAddl()
        if DEBUG:
            print "firstaddl is ", firstaddl
            print "num_sections is ", sect.num_sections
            print "K8Boundary is ", K8Boundary
        beg = firstaddl
        end = sect.num_sections
        if firstaddl < K8Boundary:
            end = K8Boundary
        obfuscate_data = []
        for i in xrange(beg, end):
            if DEBUG:
                print "Section is ", i
            data = sect.loadSection(i)
            type = data[0:4]
            if type in ["FLIS", "FCIS", "FDST", "DATP"]:
                if DEBUG:
                    print 'First 4 bytes: %s' % toHex(data[0:4])
                    fname = "%05d" % (1+i-beg)
                    fname = type + fname
                    if mh.isK8():
                        fname += "_K8"
                    fname += '.dat'
                    outname= os.path.join(files.outdir, fname)
                    file(outname, 'wb').write(data)
                    print "Skipping ", type, " section"
                imgnames.append(None)
                continue
            elif type == "SRCS":
                # The mobi file was created by kindlegen and contains a zip archive with all source files.
                # Extract the archive and save it.
                print "    Info: File contains kindlegen source archive, extracting as %s" % KINDLEGENSRC_FILENAME
                srcname = os.path.join(files.outdir, KINDLEGENSRC_FILENAME)
                file(srcname, 'wb').write(data[16:])
                imgnames.append(None)
                continue
            elif type == "FONT":
                # fonts only exist in K8 ebooks
                # Format:
                # bytes  0 -  3:  'FONT'
                # bytes  4 -  7:  uncompressed size
                # bytes  8 - 11:  flags
                #                     bit 0x0001 - zlib compression
                #                     bit 0x0002 - obfuscated with xor string
                # bytes 12 - 15:  offset to start of compressed font data
                # bytes 16 - 19:  length of xor string stored before the start of the comnpress font data
                # bytes 19 - 23:  start of xor string
                usize, fflags, dstart, xor_len, xor_start = struct.unpack_from('>LLLLL',data,4)
                font_data = data[dstart:]
                extent = len(font_data)
                extent = min(extent, 1040)
                if fflags & 0x0002:
                    # obfuscated so need to de-obfuscate the first 1040 bytes
                    key = bytearray(data[xor_start: xor_start+ xor_len])
                    buf = bytearray(font_data)
                    for n in xrange(extent):
                        buf[n] ^=  key[n%xor_len]
                    font_data = bytes(buf)
                if fflags & 0x0001:
                    # ZLIB compressed data
                    wbits, err = read_zlib_header(font_data[:2])
                    if err is None:
                        adler32, = struct.unpack_from('>I', font_data, len(font_data) - 4)
                        font_data = zlib.decompress(font_data[2:-4], -wbits, usize)
                        if len(font_data) != usize:
                            print 'Font Decompression Error: Uncompressed font size mismatch'
                        if False:
                            # For some reason these almost never match, probably Amazon has a
                            # buggy Adler32 implementation
                            sig = (zlib.adler32(font_data) & 0xffffffff)
                            if sig != adler32:
                                print 'Font Decompression Error'
                                print 'Adler checksum did not match. Stored: %d Calculated: %d' % (adler32, sig)
                    else:
                        print "Error Decoding Font", str(err)
                hdr = font_data[0:4]
                if hdr == '\0\1\0\0' or hdr == 'true' or hdr == 'ttcf':
                    ext = '.ttf'
                elif hdr == 'OTTO':
                    ext = '.otf'
                else:
                    print "Warning: unknown font header %s" % hdr.encode('hex')
                    ext = '.dat'
                fontname = "font%05d" % (1+i-beg)
                fontname += ext
                if (ext == '.ttf' or ext == '.otf') and (fflags & 0x0002):
                    obfuscate_data.append(fontname)
                print "    extracting font: ", fontname
                outfnt = os.path.join(files.imgdir, fontname)
                file(outfnt, 'wb').write(font_data)
                imgnames.append(fontname)
                continue

            elif type == "RESC":
                # resources only exist in K8 ebooks
                # not sure what they are, looks like
                # a piece of the top of the original content.opf
                # file, so only write them out
                # if DEBUG is True
                if DEBUG:
                    data = data[4:]
                    rescname = "resc%05d.dat" % (1+i-beg)
                    print "    extracting resource: ", rescname
                    outrsc = os.path.join(files.imgdir, rescname)
                    file(outrsc, 'wb').write(data)
                imgnames.append(None)
                continue

            if data == EOF_RECORD:
                if DEBUG:
                    print "Skip section %i as it contains the EOF record." % i
                imgnames.append(None)
                continue

            # if reach here should be an image but double check to make sure
            # Get the proper file extension
            imgtype = imghdr.what(None, data)
            if imgtype is None:
                print "Warning: Section %s contains no image or an unknown image format" % i
                imgnames.append(None)
                if DEBUG:
                    print 'First 4 bytes: %s' % toHex(data[0:4])
                    fname = "unknown%05d.dat" % (1+i-beg)
                    outname= os.path.join(files.outdir, fname)
                    file(outname, 'wb').write(data)
            else:
                imgname = "image%05d.%s" % (1+i-beg, imgtype)
                print "    extracting image: ", imgname
                outimg = os.path.join(files.imgdir, imgname)
                file(outimg, 'wb').write(data)
                imgnames.append(imgname)


        # FIXME all of this PrintReplica code is untested!
        # Process print replica book.
        if mh.isPrintReplica() and not k8only:
            filenames = []
            print "Print Replica ebook detected"
            try:
                mh.processPrintReplica(files)
            except Exception, e:
                print 'Error processing Print Replica: ' + str(e)
            filenames.append(['', files.getInputFileBasename() + '.pdf'])
            usedmap = {}
            for name in imgnames:
                if name != None:
                    usedmap[name] = 'used'
            opf = OPFProcessor(files, metadata, filenames, imgnames, False, mh, usedmap)
            opf.writeOPF()
            continue

        if mh.isK8():
            # K8 mobi
            # require other indexes which contain parsing information and the FDST info
            # to process the rawml back into the xhtml files, css files, svg image files, etc
            k8proc = K8Processor(mh, sect, DEBUG)
            k8proc.buildParts(rawML)

            # collect information for the guide first
            guidetext = k8proc.getGuideText()
            # add in any guide info from metadata, such as StartOffset
            if 'StartOffset' in metadata.keys():
                starts = metadata['StartOffset']
                last_start = starts.pop()
                if int(last_start) == 0xffffffff:
                    last_start = '0'
                filename, partnum, beg, end = k8proc.getFileInfo(int(last_start))
                idtext = k8proc.getIDTag(int(last_start))
                linktgt = filename
                if idtext != '':
                    linktgt += '#' + idtext
                guidetext += '<reference type="text" href="Text/%s" />\n' % linktgt

            # process the toc ncx
            # ncx map keys: name, pos, len, noffs, text, hlvl, kind, pos_fid, parent, child1, childn, num
            ncx = ncxExtract(mh, files)
            ncx_data = ncx.parseNCX()

            # extend the ncx data with
            # info about filenames and proper internal idtags
            for i in range(len(ncx_data)):
                ncxmap = ncx_data[i]
                [junk1, junk2, junk3, fid, junk4, off] = ncxmap['pos_fid'].split(':')
                filename, idtag = k8proc.getIDTagByPosFid(fid, off)
                ncxmap['filename'] = filename
                ncxmap['idtag'] = idtag
                ncx_data[i] = ncxmap

            # write out the toc.ncx
            ncx.writeK8NCX(ncx_data, metadata)

            # convert the rawML to a set of xhtml files
            htmlproc = XHTMLK8Processor(imgnames, k8proc)
            usedmap = htmlproc.buildXHTML()

            # write out the files
            filenames = []
            n =  k8proc.getNumberOfParts()
            for i in range(n):
                part = k8proc.getPart(i)
                [skelnum, dir, filename, beg, end, aidtext] = k8proc.getPartInfo(i)
                filenames.append([dir, filename])
                fname = os.path.join(files.k8oebps,dir,filename)
                file(fname,'wb').write(part)
            n = k8proc.getNumberOfFlows()
            for i in range(1, n):
                [type, format, dir, filename] = k8proc.getFlowInfo(i)
                flowpart = k8proc.getFlow(i)
                if format == 'file':
                    filenames.append([dir, filename])
                    fname = os.path.join(files.k8oebps,dir,filename)
                    file(fname,'wb').write(flowpart)

            opf = OPFProcessor(files, metadata, filenames, imgnames, ncx.isNCX, mh, usedmap, guidetext)

            if obfuscate_data:
                uuid = opf.writeOPF(True)
            else:
                uuid = opf.writeOPF()

            # make an epub of it all
            files.makeEPUB(usedmap, obfuscate_data, uuid)

        elif not k8only:
            # An original Mobi
            # process the toc ncx
            # ncx map keys: name, pos, len, noffs, text, hlvl, kind, pos_fid, parent, child1, childn, num
            ncx = ncxExtract(mh, files)
            ncx_data = ncx.parseNCX()
            ncx.writeNCX(metadata)

            positionMap = {}
            # If Dictionary build up the positionMap
            if mh.isDictionary():
                if mh.DictInLanguage():
                    metadata['DictInLanguage'] = mh.DictInLanguage()
                if mh.DictOutLanguage():
                    metadata['DictOutLanguage'] = mh.DictOutLanguage()
                positionMap = dictSupport(mh, sect).getPositionMap()

            # convert the rawml back to Mobi ml
            proc = HTMLProcessor(files, metadata, imgnames)
            srctext = proc.findAnchors(rawML, ncx_data, positionMap)
            srctext, usedmap = proc.insertHREFS()
            filenames=[]

            # write the proper mobi html
            fname = files.getInputFileBasename() + '.html'
            filenames.append(['', fname])
            outhtml = os.path.join(files.mobi7dir, fname)
            file(outhtml, 'wb').write(srctext)

            # create an OPF
            # extract guidetext from srctext
            guidetext =''
            guidematch = re.search(r'''<guide>(.*)</guide>''',srctext,re.IGNORECASE+re.DOTALL)
            if guidematch:
                replacetext = r'''href="'''+filenames[0][1]+r'''#filepos\1"'''
                guidetext = re.sub(r'''filepos=['"]{0,1}0*(\d+)['"]{0,1}''', replacetext, guidematch.group(1))
                guidetext += '\n'
                guidetext = unicode(guidetext, mh.codec).encode("utf-8")
            opf = OPFProcessor(files, metadata, filenames, imgnames, ncx.isNCX, mh, usedmap, guidetext)
            opf.writeOPF()
    return


def unpackBook(infile, outdir):
    files = fileNames(infile, outdir)

    # process the PalmDoc database header and verify it is a mobi
    sect = Sectionizer(infile)
    print "Palm DB type: ", sect.ident
    if sect.ident != 'BOOKMOBI' and sect.ident != 'TEXtREAd':
        raise unpackException('invalid file format')

    if SPLIT_COMBO_MOBIS:
        # if this is a combination mobi7-mobi8 file split them up
        mobisplit = mobi_split(infile)
        if mobisplit.combo:
            outmobi7 = os.path.join(files.outdir, 'mobi7-'+files.getInputFileBasename() + '.mobi')
            outmobi8 = os.path.join(files.outdir, 'mobi8-'+files.getInputFileBasename() + '.mobi')
            file(outmobi7, 'wb').write(mobisplit.getResult7())
            file(outmobi8, 'wb').write(mobisplit.getResult8())

    # scan sections to see if this is a compound mobi file (K8 format)
    # and build a list of all mobi headers to process.
    mhlst = []
    mh = MobiHeader(sect,0)
    # if this is a mobi8-only file hasK8 here will be true
    hasK8 = mh.isK8()
    mhlst.append(mh)
    K8Boundary = -1

    # the last section uses an appended entry of 0xfffffff as its starting point
    # attempting to process it will cause problems
    if not hasK8: # if this is a mobi8-only file we don't need to do this
        for i in xrange(len(sect.sections)-1):
            before, after = sect.sections[i:i+2]
            if (after - before) == 8:
                data = sect.loadSection(i)
                if data == K8_BOUNDARY:
                    print "Mobi Ebook uses the new K8 file format"
                    mh = MobiHeader(sect,i+1)
                    hasK8 = hasK8 or mh.isK8()
                    mhlst.append(mh)
                    K8Boundary = i
                    break
    if hasK8:
        files.makeK8Struct()
    process_all_mobi_headers(files, sect, mhlst, K8Boundary, False)
    return


class Mobi8Reader:
    def __init__(self, filename_or_stream, outdir):
        if hasattr(filename_or_stream, 'read'):
            self.stream = filename_or_stream
            self.stream.seek(0)
        else:
            self.stream = open(filename_or_stream, 'rb')
        self.files = fileNames('./ebook.mobi', outdir)

        # process the PalmDoc database header and verify it is a mobi
        self.sect = Sectionizer(self.stream)
        if self.sect.ident != 'BOOKMOBI' and self.sect.ident != 'TEXtREAd':
            raise UnpackException('invalid file format')

        # scan sections to see if this is a compound mobi file (K8 format)
        # and build a list of all mobi headers to process.
        self.mhlst = []
        mh = MobiHeader(self.sect,0)
        self.codec = mh.codec
        # if this is a mobi8-only file hasK8 here will be true
        self.hasK8 = mh.isK8()
        self.mhlst.append(mh)
        self.K8Boundary = -1

        # the last section uses an appended entry of 0xfffffff as its starting point
        # attempting to process it will cause problems
        if not self.hasK8: # if this is a mobi8-only file we don't need to do this
            for i in xrange(len(self.sect.sections)-1):
                before, after = self.sect.sections[i:i+2]
                if (after - before) == 8:
                    data = self.sect.loadSection(i)
                    if data == K8_BOUNDARY:
                        mh = MobiHeader(self.sect,i+1)
                        self.codec = mh.codec
                        self.hasK8 = self.hasK8 or mh.isK8()
                        self.mhlst.append(mh)
                        self.K8Boundary = i
                        break
        if self.hasK8:
            self.files.makeK8Struct()

    def isK8(self):
        return self.hasK8

    def getCodec(self):
        return self.codec

    def processMobi8(self):
        process_all_mobi_headers(self.files, self.sect, self.mhlst, self.K8Boundary, True)
        return os.path.join(self.files.k8dir, self.files.getInputFileBasename() + '.epub')


def usage(progname):
    print ""
    print "Description:"
    print "  Unpacks an unencrypted Kindle/MobiPocket ebook to html and images"
    print "  or an unencrypted Kindle/Print Replica ebook to PDF and images"
    print "  into the specified output folder."
    print "Usage:"
    print "  %s -r -s -d -h infile [outdir]" % progname
    print "Options:"
    print "    -r           write raw data to the output folder"
    print "    -s           split combination mobis into mobi7 and mobi8 ebooks"
    print "    -d           enable verbose debugging"
    print "    -h           print this help message"


def main(argv=sys.argv):
    global DEBUG
    global WRITE_RAW_DATA
    global SPLIT_COMBO_MOBIS
    print "MobiUnpack 0.47"
    print "  Copyright (c) 2009 Charles M. Hannum <root@ihack.net>"
    print "  With Additions by P. Durrant, K. Hendricks, S. Siebert, fandrieu, DiapDealer, nickredding."
    progname = os.path.basename(argv[0])
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hdrs")
    except getopt.GetoptError, err:
        print str(err)
        usage(progname)
        sys.exit(2)

    if len(args)<1:
        usage(progname)
        sys.exit(2)

    for o, a in opts:
        if o == "-d":
            DEBUG = True
        if o == "-r":
            WRITE_RAW_DATA = True
        if o == "-s":
            SPLIT_COMBO_MOBIS = True
        if o == "-h":
            usage(progname)
            sys.exit(0)

    if len(args) > 1:
        infile, outdir = args
    else:
        infile = args[0]
        outdir = os.path.splitext(infile)[0]

    infileext = os.path.splitext(infile)[1].upper()
    if infileext not in ['.MOBI', '.PRC', '.AZW', '.AZW4']:
        print "Error: first parameter must be a Kindle/Mobipocket ebook or a Kindle/Print Replica ebook."
        return 1

    try:
        print 'Unpacking Book...'
        unpackBook(infile, outdir)
        print 'Completed'

    except ValueError, e:
        print "Error: %s" % e
        return 1

    return 0


if __name__ == '__main__':
    sys.stdout=Unbuffered(sys.stdout)
    sys.exit(main())
