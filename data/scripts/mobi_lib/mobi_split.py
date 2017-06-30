#!/usr/bin/env python
# vim:fileencoding=UTF-8:ts=4:sw=4:sta:et:sts=4:ai

import sys
import struct
import binascii

# important  pdb header offsets
unique_id_seed = 68
number_of_pdb_records = 76

# important palmdoc header offsets
book_length = 4
book_record_count = 8
first_pdb_record = 78

# important rec0 offsets
length_of_book = 4
mobi_header_base = 16
mobi_header_length = 20
mobi_type = 24
mobi_version = 36
first_non_text = 80
title_offset = 84
first_image_record = 108
first_content_index = 192
last_content_index = 194
kf8_last_content_index = 192 # for KF8 mobi headers
fcis_index = 200
flis_index = 208
srcs_index = 224
srcs_count = 228
primary_index = 244
datp_index = 256
huffoff = 112
hufftbloff = 120

def getint(datain,ofs,sz='L'):
    i, = struct.unpack_from('>'+sz,datain,ofs)
    return i

def writeint(datain,ofs,n,len='L'):
    if len=='L':
        return datain[:ofs]+struct.pack('>L',n)+datain[ofs+4:]
    else:
        return datain[:ofs]+struct.pack('>H',n)+datain[ofs+2:]

def getsecaddr(datain,secno):
    nsec = getint(datain,number_of_pdb_records,'H')
    assert secno>=0 & secno<nsec,'secno %d out of range (nsec=%d)'%(secno,nsec)
    secstart = getint(datain,first_pdb_record+secno*8)
    if secno == nsec-1:
        secend = len(datain)
    else:
        secend = getint(datain,first_pdb_record+(secno+1)*8)
    return secstart,secend

def readsection(datain,secno):
    secstart, secend = getsecaddr(datain,secno)
    return datain[secstart:secend]

def writesection(datain,secno,secdata): # overwrite, accounting for different length
    dataout = deletesectionrange(datain,secno, secno)
    return insertsection(dataout, secno, secdata)

def nullsection(datain,secno): # make it zero-length without deleting it
    datalst = []
    nsec = getint(datain,number_of_pdb_records,'H')
    secstart, secend = getsecaddr(datain,secno)
    zerosecstart, zerosecend = getsecaddr(datain, 0)
    dif =  secend-secstart
    datalst.append(datain[:first_pdb_record])
    for i in range(0,secno+1):
        ofs, flgval = struct.unpack_from('>2L',datain,first_pdb_record+i*8)
        datalst.append(struct.pack('>L',ofs) + struct.pack('>L', flgval))
    for i in range(secno+1, nsec):
        ofs, flgval = struct.unpack_from('>2L',datain,first_pdb_record+i*8)
        ofs = ofs - dif
        datalst.append(struct.pack('>L',ofs) + struct.pack('>L',flgval))
    lpad = zerosecstart - (first_pdb_record + 8*nsec)
    if lpad > 0:
        datalst.append('\0' * lpad)
    datalst.append(datain[zerosecstart: secstart])
    datalst.append(datain[secend:])
    dataout = "".join(datalst)
    return dataout

def deletesectionrange(datain,firstsec,lastsec): # delete a range of sections
    datalst = []
    firstsecstart,firstsecend = getsecaddr(datain,firstsec)
    lastsecstart,lastsecend = getsecaddr(datain,lastsec)
    zerosecstart, zerosecend = getsecaddr(datain, 0)
    dif = lastsecend - firstsecstart + 8*(lastsec-firstsec+1)
    nsec = getint(datain,number_of_pdb_records,'H')
    datalst.append(datain[:unique_id_seed])
    datalst.append(struct.pack('>L',2*(nsec-(lastsec-firstsec+1))+1))
    datalst.append(datain[unique_id_seed+4:number_of_pdb_records])
    datalst.append(struct.pack('>H',nsec-(lastsec-firstsec+1)))
    newstart = zerosecstart - 8*(lastsec-firstsec+1)
    for i in range(0,firstsec):
        ofs, flgval = struct.unpack_from('>2L',datain,first_pdb_record+i*8)
        ofs = ofs-8*(lastsec-firstsec+1)
        datalst.append(struct.pack('>L',ofs) + struct.pack('>L', flgval))
    for i in range(lastsec+1,nsec):
        ofs, flgval = struct.unpack_from('>2L',datain,first_pdb_record+i*8)
        ofs = ofs - dif
        flgval = 2*(i-(lastsec-firstsec+1))
        datalst.append(struct.pack('>L',ofs) + struct.pack('>L',flgval))
    lpad = newstart - (first_pdb_record + 8*(nsec - (lastsec - firstsec + 1)))
    if lpad > 0:
        datalst.append('\0' * lpad)
    datalst.append(datain[zerosecstart:firstsecstart])
    datalst.append(datain[lastsecend:])
    dataout = "".join(datalst)
    return dataout

def insertsection(datain,secno,secdata): # insert a new section
    datalst = []
    nsec = getint(datain,number_of_pdb_records,'H')
    secstart,secend = getsecaddr(datain,secno)
    zerosecstart,zerosecend = getsecaddr(datain,0)
    dif = len(secdata)
    datalst.append(datain[:unique_id_seed])
    datalst.append(struct.pack('>L',2*(nsec+1)+1))
    datalst.append(datain[unique_id_seed+4:number_of_pdb_records])
    datalst.append(struct.pack('>H',nsec+1))
    newstart = zerosecstart + 8
    totoff = 0
    for i in range(0,secno):
        ofs, flgval = struct.unpack_from('>2L',datain,first_pdb_record+i*8)
        ofs += 8
        datalst.append(struct.pack('>L',ofs) + struct.pack('>L', flgval))
    datalst.append(struct.pack('>L', secstart + 8) + struct.pack('>L', (2*secno)))
    for i in range(secno,nsec):
        ofs, flgval = struct.unpack_from('>2L',datain,first_pdb_record+i*8)
        ofs = ofs + dif + 8
        flgval = 2*(i+1)
        datalst.append(struct.pack('>L',ofs) + struct.pack('>L',flgval))
    lpad = newstart - (first_pdb_record + 8*(nsec + 1))
    if lpad > 0:
        datalst.append('\0' * lpad)
    datalst.append(datain[zerosecstart:secstart])
    datalst.append(secdata)
    datalst.append(datain[secstart:])
    dataout = "".join(datalst)
    return dataout


def insertsectionrange(sectionsource,firstsec,lastsec,sectiontarget,targetsec): # insert a range of sections
    dataout = sectiontarget
    for idx in range(lastsec,firstsec-1,-1):
        dataout = insertsection(dataout,targetsec,readsection(sectionsource,idx))
    return dataout

def get_exth_params(rec0):
    ebase = mobi_header_base + getint(rec0,mobi_header_length)
    elen = getint(rec0,ebase+4)
    enum = getint(rec0,ebase+8)
    return ebase,elen,enum

def add_exth(rec0,exth_num,exth_bytes):
    ebase,elen,enum = get_exth_params(rec0)
    newrecsize = 8+len(exth_bytes)
    newrec0 = rec0[0:ebase+4]+struct.pack('>L',elen+newrecsize)+struct.pack('>L',enum+1)+\
              struct.pack('>L',exth_num)+struct.pack('>L',newrecsize)+exth_bytes+rec0[ebase+12:]
    newrec0 = writeint(newrec0,title_offset,getint(newrec0,title_offset)+newrecsize)
    return newrec0

def read_exth(rec0,exth_num):
    ebase,elen,enum = get_exth_params(rec0)
    ebase = ebase+12
    while enum>0:
        exth_id = getint(rec0,ebase)
        if exth_id == exth_num:
            return rec0[ebase+8:ebase+getint(rec0,ebase+4)]
        enum = enum-1
        ebase = ebase+getint(rec0,ebase+4)
    return ''

def write_exth(rec0,exth_num,exth_bytes):
    ebase,elen,enum = get_exth_params(rec0)
    ebase_idx = ebase+12
    enum_idx = enum
    while enum_idx>0:
        exth_id = getint(rec0,ebase_idx)
        if exth_id == exth_num:
            dif = len(exth_bytes)+8-getint(rec0,ebase_idx+4)
            newrec0 = rec0
            if dif != 0:
                newrec0 = writeint(newrec0,title_offset,getint(newrec0,title_offset)+dif)
            return newrec0[:ebase+4]+struct.pack('>L',elen+len(exth_bytes)+8-getint(rec0,ebase_idx+4))+\
                                              struct.pack('>L',enum)+rec0[ebase+12:ebase_idx+4]+\
                                              struct.pack('>L',len(exth_bytes)+8)+exth_bytes+\
                                              rec0[ebase_idx+getint(rec0,ebase_idx+4):]
        enum_idx = enum_idx-1
        ebase_idx = ebase_idx+getint(rec0,ebase_idx+4)
    return rec0

def del_exth(rec0,exth_num):
    ebase,elen,enum = get_exth_params(rec0)
    ebase_idx = ebase+12
    enum_idx = enum
    while enum_idx>0:
        exth_id = getint(rec0,ebase_idx)
        if exth_id == exth_num:
            dif = getint(rec0,ebase_idx+4)
            newrec0 = rec0
            newrec0 = writeint(newrec0,title_offset,getint(newrec0,title_offset)-dif)
            newrec0 = newrec0[:ebase_idx]+newrec0[ebase_idx+dif:]
            newrec0 = newrec0[0:ebase+4]+struct.pack('>L',elen-dif)+struct.pack('>L',enum-1)+newrec0[ebase+12:]
            return newrec0
        enum_idx = enum_idx-1
        ebase_idx = ebase_idx+getint(rec0,ebase_idx+4)
    return rec0


class mobi_split:

    def __init__(self, infile):
        datain = file(infile, 'rb').read()
        datain_rec0 = readsection(datain,0)
        ver = getint(datain_rec0,mobi_version)
        self.combo = (ver!=8)
        if not self.combo:
            return
        exth121 = read_exth(datain_rec0,121)
        if len(exth121) == 0:
            self.combo = False
            return
        else:
            datain_kf8, = struct.unpack_from('>L',exth121,0)
            if datain_kf8 == 0xffffffff:
                self.combo = False
                return
        datain_kfrec0 =readsection(datain,datain_kf8)

        # create the standalone mobi7
        num_sec = getint(datain,number_of_pdb_records,'H')
        # remove BOUNDARY up to but not including ELF record
        self.result_file7 = deletesectionrange(datain,datain_kf8-1,num_sec-2)
        # check if there are SRCS records and delete them
        srcs = getint(datain_rec0,srcs_index)
        num_srcs = getint(datain_rec0,srcs_count)
        if srcs > 0:
            self.result_file7 = deletesectionrange(self.result_file7,srcs,srcs+num_srcs-1)
            datain_rec0 = writeint(datain_rec0,srcs_index,0xffffffff)
            datain_rec0 = writeint(datain_rec0,srcs_count,0)
        # reset the EXTH 121 KF8 Boundary meta data to 0xffffffff
        datain_rec0 = write_exth(datain_rec0,121, struct.pack('>L', 0xffffffff))
        # don't remove the EXTH 125 KF8 Count of Resources, seems to be present in mobi6 files as well
        # set the EXTH 129 KF8 Masthead / Cover Image string to the null string
        datain_rec0 = write_exth(datain_rec0,129, '')
        # don't remove the EXTH 131 KF8 Unidentified Count, seems to be present in mobi6 files as well

        # need to reset flags stored in 0x80-0x83
        # old mobi with exth: 0x50, mobi7 part with exth: 0x1850, mobi8 part with exth: 0x1050
        # Bit Flags?
        # 0x1000 = KF8 dual mobi
        # 0x0800 = means this Header points to *shared* images/resource/fonts
        # 0x0040 = exth exists
        # 0x0010 = Not sure but this is always set so far
        fval, = struct.unpack_from('>L',datain_rec0, 0x80)
        fval = fval & 0x00FF
        datain_rec0 = datain_rec0[:0x80] + struct.pack('>L',fval) + datain_rec0[0x84:]

        self.result_file7 = writesection(self.result_file7,0,datain_rec0)

        # no need to replace kf8 style fcis with mobi 7 one
        # fcis_secnum, = struct.unpack_from('>L',datain_rec0, 0xc8)
        # if fcis_secnum != 0xffffffff:
        #     fcis_info = readsection(datain, fcis_secnum)
        #     text_len,  = struct.unpack_from('>L', fcis_info, 0x14)
        #     new_fcis = 'FCIS\x00\x00\x00\x14\x00\x00\x00\x10\x00\x00\x00\x01\x00\x00\x00\x00'
        #     new_fcis += struct.pack('>L',text_len)
        #     new_fcis += '\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x08\x00\x01\x00\x01\x00\x00\x00\x00'
        #     self.result_file7 = writesection(self.result_file7, fcis_secnum, new_fcis)

        firstimage = getint(datain_rec0,first_image_record)
        lastimage = getint(datain_rec0,last_content_index,'H')

        # No need to null out FONT and RES, but leave the (empty) PDB record so image refs remain valid
        # for i in range(firstimage,lastimage):
        #     imgsec = readsection(self.result_file7,i)
        #     if imgsec[0:4] in ['RESC','FONT']:
        #         self.result_file7 = nullsection(self.result_file7,i)

        # mobi7 finished

        # create standalone mobi8
        self.result_file8 = deletesectionrange(datain,0,datain_kf8-1)
        target = getint(datain_kfrec0,first_image_record)
        self.result_file8 = insertsectionrange(datain,firstimage,lastimage,self.result_file8,target)
        datain_kfrec0 =readsection(self.result_file8,0)

        # update the EXTH 125 KF8 Count of Images/Fonts/Resources
        datain_kfrec0 = write_exth(datain_kfrec0,125,struct.pack('>L',lastimage-firstimage+1))

        # need to reset flags stored in 0x80-0x83
        # old mobi with exth: 0x50, mobi7 part with exth: 0x1850, mobi8 part with exth: 0x1050
        # standalone mobi8 with exth: 0x0050
        fval, = struct.unpack_from('>L',datain_kfrec0, 0x80)
        fval = fval & 0x00FF
        datain_kfrec0 = datain_kfrec0[:0x80] + struct.pack('>L',fval) + datain_kfrec0[0x84:]

        # properly update other index pointers that have been shifted by the insertion of images
        ofs_list = [(kf8_last_content_index,'L'),(fcis_index,'L'),(flis_index,'L'),(datp_index,'L'),(hufftbloff, 'L')]
        for ofs,sz in ofs_list:
            n = getint(datain_kfrec0,ofs,sz)
            if n>0:
                datain_kfrec0 = writeint(datain_kfrec0,ofs,n+lastimage-firstimage+1,sz)
        self.result_file8 = writesection(self.result_file8,0,datain_kfrec0)

        # no need to replace kf8 style fcis with mobi 7 one
        # fcis_secnum, = struct.unpack_from('>L',datain_kfrec0, 0xc8)
        # if fcis_secnum != 0xffffffff:
        #     fcis_info = readsection(self.result_file8, fcis_secnum)
        #     text_len,  = struct.unpack_from('>L', fcis_info, 0x14)
        #     new_fcis = 'FCIS\x00\x00\x00\x14\x00\x00\x00\x10\x00\x00\x00\x01\x00\x00\x00\x00'
        #     new_fcis += struct.pack('>L',text_len)
        #     new_fcis += '\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x08\x00\x01\x00\x01\x00\x00\x00\x00'
        #     self.result_file8 = writesection(self.result_file8, fcis_secnum, new_fcis)

        # mobi8 finished

    def getResult8(self):
        return self.result_file8

    def getResult7(self):
        return self.result_file7
