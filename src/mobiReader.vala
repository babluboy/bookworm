/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and is used for parsing MOBI file formats
* The Mobi unpack utility mobi_unpack.py (v0.47) by adamselene
* is used to extract the contents of the mobi file
*
* Bookworm is free software: you can redistribute it
* and/or modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation, either version 3 of the
* License, or (at your option) any later version.
*
* Bookworm is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with Bookworm. If not, see http://www.gnu.org/licenses/.
*/

using Gee;
public class BookwormApp.mobiReader {
    public static string OpfContents = "";

    public static BookwormApp.Book parseMobiBook (owned BookwormApp.Book aBook) {
        info ("[START] [FUNCTION:parseMobiBook] book.location=" + aBook.getBookLocation ());
        //Only parse the eBook if it has not been parsed already
        if (!aBook.getIsBookParsed ()) {
            //Extract the content of the EPub
            string extractionLocation = extractEBook (aBook.getBookLocation ());
            if ("false" == extractionLocation) { //handle error condition
                aBook.setIsBookParsed (false);
                aBook.setParsingIssue (BookwormApp.Constants.TEXT_FOR_EXTRACTION_ISSUE);
                return aBook;
            } else {
                aBook.setBookExtractionLocation (extractionLocation);
            }
            //Determine the location of OPF File
            string locationOfOPFFile = getOPFFileLocation (extractionLocation);
            if ("false" == locationOfOPFFile) { //handle error condition
                aBook.setIsBookParsed (false);
                aBook.setParsingIssue (BookwormApp.Constants.TEXT_FOR_CONTENT_ISSUE);
                return aBook;
            }
            string baseLocationOfContents = locationOfOPFFile.replace (File.new_for_path (locationOfOPFFile).get_basename (), "");
            aBook.setBaseLocationOfContents (baseLocationOfContents);
            //Determine Manifest contents
            ArrayList<string> manifestItemsList = parseManifestData (locationOfOPFFile);
            if ("false" == manifestItemsList.get (0)) {
                aBook.setIsBookParsed (false);
                aBook.setParsingIssue (BookwormApp.Constants.TEXT_FOR_CONTENT_ISSUE);
                return aBook;
            }
            //Determine Spine contents
            ArrayList<string> spineItemsList = parseSpineData (locationOfOPFFile);
            if ("false" == spineItemsList.get (0)) {
                aBook.setIsBookParsed (false);
                aBook.setParsingIssue (BookwormApp.Constants.TEXT_FOR_CONTENT_ISSUE);
                return aBook;
            }
            //Match Spine with Manifest to populate content list for EPub Book
            aBook = getContentList (aBook, manifestItemsList, spineItemsList);
            if (aBook.getBookContentList ().size < 1) {
                aBook.setIsBookParsed (false);
                aBook.setParsingIssue (BookwormApp.Constants.TEXT_FOR_CONTENT_ISSUE);
                return aBook;
            }
            //Try to determine Book Cover Image if it is not already available
            if (!aBook.getIsBookCoverImagePresent ()) {
                aBook = setCoverImage (aBook, manifestItemsList);
            }
            //Determine Book Meta Data like Title, Author, etc
            aBook = setBookMetaData (aBook, locationOfOPFFile);
            aBook.setIsBookParsed (true);
        } else {
            debug ("eBook already parsed, skipping MOBI parsing. book.location=" + aBook.getBookLocation ());
        }
        info ("[END] [FUNCTION:parseMobiBook] book.location=" + aBook.getBookLocation ());
        return aBook;
    }

    public static string extractEBook (string eBookLocation) {
        info ("[START] [FUNCTION:extractEBook] book.location=" + eBookLocation);
        string extractionLocation = "false";
        debug ("Initiated process for content extraction of mobi Book located at:" + eBookLocation);
        //create a location for extraction of eBook based on local storage prefference
        if (BookwormApp.Bookworm.settings == null) {
            BookwormApp.Bookworm.settings = BookwormApp.Settings.get_instance ();
        }
        if (BookwormApp.Bookworm.settings.is_local_storage_enabled) {
            extractionLocation = BookwormApp.Bookworm.bookworm_config_path + "/books/" + File.new_for_path (eBookLocation).get_basename ();
        } else {
            extractionLocation = BookwormApp.Constants.EBOOK_EXTRACTION_LOCATION + File.new_for_path (eBookLocation).get_basename ();
        }
        //check and create directory for extracting contents of ebook
        BookwormApp.Utils.fileOperations ("CREATEDIR", extractionLocation, "", "");
        //extract eBook contents into extraction location
        BookwormApp.Utils.execute_sync_command (BookwormApp.Constants.MOBIUNPACK_SCRIPT_LOCATION +
            " \"" + eBookLocation + "\" \"" + extractionLocation + "/\"");
        info ("[END] [FUNCTION:extractEBook] extractionLocation=" + extractionLocation);
        return extractionLocation;
    }

    public static string getOPFFileLocation (string extractionLocation) {
        info ("[START] [FUNCTION:getOPFFileLocation] extractionLocation=" + extractionLocation);
        string locationOfOPFFile = "false";
        //Check if the "mobi7" folder is present
        string isMobiExtractionFolderPresent = BookwormApp.Utils.fileOperations ("DIR_EXISTS", extractionLocation + "/mobi7", "", "");
        if ("false" != isMobiExtractionFolderPresent) {
            //check for presence of .opf file
            locationOfOPFFile = BookwormApp.Utils.execute_sync_command ("find " +
                "\"" + extractionLocation + "/mobi7/" + "\"" + " -iname *.OPF").strip ();
        } else {
            return "false";
        }
        info ("[END] [FUNCTION:getOPFFileLocation] locationOfOPFFile=" + locationOfOPFFile);
        return locationOfOPFFile;
    }

    public static ArrayList<string> parseManifestData (string locationOfOPFFile) {
        info ("[START] [FUNCTION:parseManifestData] locationOfOPFFile=" + locationOfOPFFile);
        ArrayList<string> manifestItemsList = new ArrayList<string> ();
        //read contents from content.opf file - using cat command as the reading of file is not working - check !
        //string OpfContents = BookwormApp.Utils.fileOperations ("READ_FILE", locationOfOPFFile, "", "");
        OpfContents = BookwormApp.Utils.execute_sync_command ("cat \"" + locationOfOPFFile + "\"");
        if (OpfContents.contains ("No such file or directory")) {
            //OPF Contents could not be read from file
            warning ("OPF contents could not be read from file:" + locationOfOPFFile);
            manifestItemsList.add ("false");
            return manifestItemsList;
        }
        string manifestData = "";
        try {
            manifestData = BookwormApp.Utils.extractXMLTag (OpfContents, "<manifest", "</manifest>");
        } catch (Error e) {
            warning ("Error while parsing manifest data [" + OpfContents + "] :" + e.message);
        }
        string[] manifestList = BookwormApp.Utils.multiExtractBetweenTwoStrings (manifestData, "<item", ">");
        foreach (string manifestItem in manifestList) {
            debug ("Manifest Item=" + manifestItem);
            manifestItemsList.add (manifestItem);
        }
        if (manifestItemsList.size < 1) {
            //OPF Contents could not be read from file
            warning ("OPF contents could not be read from file:" + locationOfOPFFile);
            manifestItemsList.add ("false");
            return manifestItemsList;
        }
        info ("[END] [FUNCTION:parseManifestData] manifestItemsList.size=" + manifestItemsList.size.to_string ());
        return manifestItemsList;
    }

    public static ArrayList<string> parseSpineData (string locationOfOPFFile) {
        info ("[START] [FUNCTION:parseSpineData] locationOfOPFFile=" + locationOfOPFFile);
        ArrayList<string> spineItemsList = new ArrayList<string> ();
        string spineData = "";
        try {
            spineData = BookwormApp.Utils.extractXMLTag (OpfContents, "<spine", "</spine>");
        } catch (Error e) {
            warning ("Error while parsing spine data [" + OpfContents + "] :" + e.message);
        }
        //check TOC id in Spine data and add as first item to Spine List
        int startTOCPosition = spineData.index_of ("toc=\"");
        int endTOCPosition = spineData.index_of ("\"", startTOCPosition + ("toc=\"").length + 1);
        if (startTOCPosition != -1 && endTOCPosition != -1 && endTOCPosition>startTOCPosition) {
            spineItemsList.add (spineData.slice (startTOCPosition, endTOCPosition));
            debug ("TOC ID=" + spineData.slice (startTOCPosition, endTOCPosition));
        }
        string[] spineList = BookwormApp.Utils.multiExtractBetweenTwoStrings (spineData, "<itemref", ">");
        foreach (string spineItem in spineList) {
            debug ("Spine Item=" + spineItem);
            spineItemsList.add (spineItem);
        }
        if (spineItemsList.size < 1) {
            //OPF Contents could not be read from file
            warning ("Spine contents could not be read from file:" + locationOfOPFFile);
            spineItemsList.add ("false");
            return spineItemsList;
        }
        info ("[END] [FUNCTION:parseSpineData] spineItemsList.size=" + spineItemsList.size.to_string ());
        return spineItemsList;
    }

    public static BookwormApp.Book getContentList (
        owned BookwormApp.Book aBook,
        ArrayList<string> manifestItemsList,
        ArrayList<string> spineItemsList
    ) {
        info ("[START] [FUNCTION:getContentList] book.location=" + aBook.getBookLocation ());
        StringBuilder bufferForSpineData = new StringBuilder ("");
        StringBuilder bufferForLocationOfContentData = new StringBuilder ("");
        ArrayList<string> tocList = new ArrayList<string> ();
        //extract location of ncx file if present on the first index of the Spine List
        if (spineItemsList.get (0).contains ("toc=\"")) {
            int tocRefStartPos = spineItemsList.get (0).index_of ("toc=\"") + ("toc=\"").length;
            if ( (tocRefStartPos- ("toc=\"").length) != -1 && spineItemsList.get (0).length > tocRefStartPos) {
                bufferForSpineData.assign (spineItemsList.get (0).slice (tocRefStartPos, spineItemsList.get (0).length));
            } else {
                bufferForSpineData.assign ("");
            }
            if (bufferForSpineData.str.length > 0) {
                //loop over manifest data to get location of TOC file
                foreach (string manifestItem in manifestItemsList) {
                    if (manifestItem.index_of ("id=\"" + bufferForSpineData.str + "\"") != -1) {
                        int startPosOfNCXContentItem = manifestItem.index_of ("href=") + ("href=").length + 1 ;
                        int endPosOfNCXContentItem = manifestItem.index_of ("\"", startPosOfNCXContentItem + 1);
                        if (startPosOfNCXContentItem != -1 && endPosOfNCXContentItem != -1 && endPosOfNCXContentItem > startPosOfNCXContentItem) {
                            bufferForLocationOfContentData.assign (manifestItem.slice (startPosOfNCXContentItem, endPosOfNCXContentItem));
                            debug ("SpineData=" + bufferForSpineData.str + " | Location Of NCX ContentData=" + bufferForLocationOfContentData.str);
                            //Read ncx file
                            string navigationData = BookwormApp.Utils.fileOperations ("READ_FILE", (BookwormApp.Utils.getFullPathFromFilename (aBook.getBaseLocationOfContents (), bufferForLocationOfContentData.str.strip ())).strip (), "", "");
                            string[] navPointList = BookwormApp.Utils.multiExtractBetweenTwoStrings (navigationData, "<navPoint", "</navPoint>");
                            if (navPointList.length > 0) {
                                foreach (string navPointItem in navPointList) {
                                    string tocText = "";
                                    try {
                                        tocText = BookwormApp.Utils.decodeHTMLChars (BookwormApp.Utils.extractXMLTag (navPointItem, "<text>", "</text>"));
                                    } catch (Error e) {
                                        warning ("Error while parsing ToC data [" + navPointItem + "] : " + e.message);
                                    }
                                    int tocNavStartPoint = navPointItem.index_of ("src=\"");
                                    int tocNavEndPoint = navPointItem.index_of ("\"", tocNavStartPoint + ("src=\"").length);
                                    if (tocNavStartPoint != -1 && tocNavEndPoint != -1 && tocNavEndPoint>tocNavStartPoint) {
                                        string tocNavLocation = navPointItem.slice (tocNavStartPoint + ("src=\"").length, tocNavEndPoint).strip ();
                                        if (tocNavLocation.length>0) {
                                            tocList.add (tocNavLocation + "~~$$~~" + tocText);
                                        }
                                    }
                                }
                            }
                        }
                        break;
                    }
                }
            }
        }
        // Clear the content list of any previous items
        aBook.clearBookContentList ();
        //loop over remaning spine items (ncx file will be ignored as it will not have a prefix of idref)
        foreach (string spineItem in spineItemsList) {
            int startPosOfSpineItem = spineItem.index_of ("idref=") + ("idref=").length + 1;
            int endPosOfSpineItem = spineItem.index_of ("\"", startPosOfSpineItem + 1);
            if (startPosOfSpineItem != -1 && endPosOfSpineItem != -1 && endPosOfSpineItem>startPosOfSpineItem) {
                bufferForSpineData.assign (spineItem.slice (startPosOfSpineItem, endPosOfSpineItem));
            } else {
                bufferForSpineData.assign (""); //clear spine buffer if the data does not contain idref
            }
            if (bufferForSpineData.str.length > 0) {
                //loop over manifest items to match the spine item
                foreach (string manifestItem in manifestItemsList) {
                    if (manifestItem.contains ("id=\"" + bufferForSpineData.str + "\"")) {
                        int startPosOfContentItem = manifestItem.index_of ("href=") + ("href=").length + 1 ;
                        int endPosOfContentItem = manifestItem.index_of ("\"", startPosOfContentItem + 1);
                        if (startPosOfContentItem != -1 && endPosOfContentItem != -1 && endPosOfContentItem>startPosOfContentItem) {
                            bufferForLocationOfContentData.assign (manifestItem.slice (startPosOfContentItem, endPosOfContentItem));
                            debug ("SpineData=" + bufferForSpineData.str + " | LocationOfContentData=" + bufferForLocationOfContentData.str);
                            //split the content data in the html file based on the position IDs in the .ncx file
                            string locationOfBookHTMLFile = aBook.getBaseLocationOfContents () + bufferForLocationOfContentData.str;
                            File mobiHTMLFile = File.new_for_path (locationOfBookHTMLFile);
                            if (!mobiHTMLFile.query_exists ()) {
                                warning ("Main HTML File for book doesn't exist at location:" + locationOfBookHTMLFile);
                                //handle condition of not being able to split file
                            } else { //HTML File exists - split HTML file
                                StringBuilder mobiHTMLContent = new StringBuilder ();
                                mobiHTMLContent.assign (BookwormApp.Utils.fileOperations ("READ_FILE", locationOfBookHTMLFile, "", ""));
                                int splitStartPos = 0;
                                int splitEndPos = mobiHTMLContent.str.length;
                                StringBuilder tocIDValue = new StringBuilder ("");
                                StringBuilder splitFileName = new StringBuilder ("_ (Start)");
                                StringBuilder splitHTMLContent = new StringBuilder ("");
                                StringBuilder splitPosIdentifierString = new StringBuilder ("");
                                StringBuilder tocName = new StringBuilder ("");
                                //Loop through the table of contents and split into smaller HTML files
                                if (tocList.size > 0) {
                                    foreach (string tocItem in tocList) {
                                        string[] tocItemAttributes = tocItem.split ("~~$$~~", -1);
                                        //get the value of the bookmarkID from the content list
                                        debug ("parsing bookmark value:" + tocItemAttributes[0]);
                                        tocIDValue.assign (tocItemAttributes[0].slice (tocItemAttributes[0].index_of ("#") + 1, tocItemAttributes[0].length));
                                        splitPosIdentifierString.assign ("<a id=\"" + tocIDValue.str + "\"");
                                        //check if bookmark id is present in html data
                                        if (mobiHTMLContent.str.index_of (splitPosIdentifierString.str) != -1) {
                                            splitHTMLContent.assign (mobiHTMLContent.str.slice (splitStartPos, mobiHTMLContent.str.index_of (splitPosIdentifierString.str)));
                                            splitHTMLContent.prepend ("<html><body>");
                                            splitHTMLContent.append ("</body></html>");
                                            //write the split data to file
                                            BookwormApp.Utils.fileOperations ("WRITE", aBook.getBaseLocationOfContents () + "split_html", splitFileName.str + ".html", splitHTMLContent.str);
                                            //set book content list
                                            aBook.setBookContentList (aBook.getBaseLocationOfContents () + "split_html/" + splitFileName.str + ".html");
                                            //set TOC name and path to split html file
                                            HashMap<string, string> TOCMapItemUpdated = new HashMap<string, string> ();
                                            TOCMapItemUpdated.set (aBook.getBaseLocationOfContents () + "split_html/" + splitFileName.str + ".html", tocName.str);
                                            aBook.setTOC (TOCMapItemUpdated);
                                            debug ("Updating TOC:" + aBook.getBaseLocationOfContents () + "split_html/" + splitFileName.str + ".html" + "::" + tocName.str);
                                            //Set the next start position, chapter name and file name
                                            splitStartPos = mobiHTMLContent.str.index_of (splitPosIdentifierString.str);
                                            splitFileName.assign (tocIDValue.str);
                                            tocName.assign (tocItemAttributes[1]);
                                        }
                                    }
                                    //check if any contents are left from the main html file and write it into the last split file
                                    if (splitEndPos > splitStartPos) {
                                        splitHTMLContent.assign (mobiHTMLContent.str.slice (splitStartPos, splitEndPos));
                                        splitHTMLContent.prepend ("<html><body>");
                                        splitHTMLContent.append ("</body></html>");
                                        //write the split data to file
                                        BookwormApp.Utils.fileOperations ("WRITE", aBook.getBaseLocationOfContents () + "split_html", splitFileName.str + ".html", splitHTMLContent.str);
                                        //set book content list
                                        aBook.setBookContentList (aBook.getBaseLocationOfContents () + "split_html/" + splitFileName.str + ".html");
                                        //set TOC name and path to split html file
                                        HashMap<string, string> TOCMapItem = new HashMap<string, string> ();
                                        TOCMapItem.set (aBook.getBaseLocationOfContents () + "split_html/" + splitFileName.str + ".html", tocName.str);
                                        aBook.setTOC (TOCMapItem);
                                    }
                                } else {
                                    //set book content list for the unpacked HTML file
                                    aBook.setBookContentList (locationOfBookHTMLFile);
                                    //set TOC name and path to the unpacked HTML file
                                    HashMap<string, string> TOCMapItem = new HashMap<string, string> ();
                                    TOCMapItem.set (locationOfBookHTMLFile, _ ("Book"));
                                    aBook.setTOC (TOCMapItem);
                                    /*
                                    //No chapter IDs in the NCX file : split file by <mbp:pagebreak/>
                                    splitPosIdentifierString.assign ("<mbp:pagebreak/>");
                                    int countOfSections = 1;
                                    tocName.assign (_ ("Section ") + countOfSections.to_string ());
                                    splitFileName.assign (tocName.str);
                                    //check if pagebreak tag is present in html data
                                    while ( (splitStartPos > -1) && (mobiHTMLContent.str.index_of (splitPosIdentifierString.str, splitStartPos + 1) != -1)) {
                                        splitHTMLContent.assign (mobiHTMLContent.str.slice (splitStartPos, mobiHTMLContent.str.index_of (splitPosIdentifierString.str, splitStartPos + 1)));
                                        splitHTMLContent.prepend ("<html><body>");
                                        splitHTMLContent.append ("</body></html>");
                                        //write the split data to file
                                        BookwormApp.Utils.fileOperations ("WRITE", aBook.getBaseLocationOfContents () + "split_html", splitFileName.str + ".html", splitHTMLContent.str);
                                        //set book content list
                                        aBook.setBookContentList (aBook.getBaseLocationOfContents () + "split_html/" + splitFileName.str + ".html");
                                        //set TOC name and path to split html file
                                        HashMap<string, string> TOCMapItemUpdated = new HashMap<string, string> ();
                                        TOCMapItemUpdated.set (aBook.getBaseLocationOfContents () + "split_html/" + splitFileName.str + ".html", tocName.str);
                                        aBook.setTOC (TOCMapItemUpdated);
                                        debug ("Updating TOC:" + aBook.getBaseLocationOfContents () + "split_html/" + splitFileName.str + ".html" + "::" + tocName.str);
                                        //Set the next start position, at the next occurence of <mbp:pagebreak/>
                                        splitStartPos = mobiHTMLContent.str.index_of (splitPosIdentifierString.str, splitStartPos + splitPosIdentifierString.str.length);
                                        debug ("splitStartPos:" + splitStartPos.to_string ());
                                        countOfSections++;
                                        tocName.assign (_ ("Section ") + countOfSections.to_string ());
                                        splitFileName.assign (tocName.str);
                                    }*/
                                }
                            }
                        }
                        break;
                    }
                }
            }
        }
        info ("[END] [FUNCTION:getContentList] tocList.size=" + tocList.size.to_string ());
        return aBook;
    }

    public static BookwormApp.Book setCoverImage (owned BookwormApp.Book aBook, ArrayList<string> manifestItemsList) {
        info ("[START] [FUNCTION:setCoverImage] book.location=" + aBook.getBookLocation ());
        string bookCoverLocation = "";
        //determine the location of the book's cover image
        if (OpfContents.contains ("<meta name=\"Cover ThumbNail Image\"") && OpfContents.contains ("content=\"")) {
            int startOfCoverImageLocation = OpfContents.index_of ("content=\"", OpfContents.index_of ("<meta name=\"Cover ThumbNail Image\""));
            int endOfCoverImageLocation = OpfContents.index_of ("\" />", startOfCoverImageLocation);
            if (startOfCoverImageLocation != -1 && endOfCoverImageLocation != -1 && endOfCoverImageLocation > startOfCoverImageLocation) {
                bookCoverLocation = aBook.getBaseLocationOfContents () + BookwormApp.Utils.decodeHTMLChars (
                    OpfContents.slice (startOfCoverImageLocation + "content=\"".length, endOfCoverImageLocation));
                debug ("Determined eBook Cover Image Location as:" + bookCoverLocation);
            }
        }
        //check if cover was not found and assign flag
        if (bookCoverLocation == null || bookCoverLocation.length < 1) {
            aBook.setIsBookCoverImagePresent (false);
            debug ("Cover image not found for book located at:" + aBook.getBookExtractionLocation ());
        } else {
            //copy cover image to bookworm cover image cache
            aBook = BookwormApp.Utils.setBookCoverImage (aBook, bookCoverLocation);
        }
        info ("[END] [FUNCTION:setCoverImage] bookCoverLocation=" + bookCoverLocation);
        return aBook;
    }

    public static BookwormApp.Book setBookMetaData (owned BookwormApp.Book aBook, string locationOfOPFFile) {
        info ("[START] [FUNCTION:setBookMetaData] book.location=" + aBook.getBookLocation ());
        //determine the title of the book from contents if it is not already available
        if (aBook.getBookTitle () != null && aBook.getBookTitle ().length < 1) {
            if (OpfContents.contains ("<dc:title") && OpfContents.contains ("</dc:title>")) {
                int startOfTitleText = OpfContents.index_of (">", OpfContents.index_of ("<dc:title"));
                int endOfTittleText = OpfContents.index_of ("</dc:title>", startOfTitleText);
                if (startOfTitleText != -1 && endOfTittleText != -1 && endOfTittleText > startOfTitleText) {
                    string bookTitle = BookwormApp.Utils.decodeHTMLChars (OpfContents.slice (startOfTitleText + 1, endOfTittleText));
                    aBook.setBookTitle (bookTitle);
                    debug ("Determined eBook Title as:" + bookTitle);
                }
            }
        }
        //If the book title has still not been determined, use the file name as book title
        if (aBook.getBookTitle () != null && aBook.getBookTitle ().length < 1) {
            string bookTitle = File.new_for_path (aBook.getBookExtractionLocation ()).get_basename ();
            if (bookTitle.last_index_of (".") != -1) {
                bookTitle = bookTitle.slice (0, bookTitle.last_index_of ("."));
            }
            aBook.setBookTitle (bookTitle);
            debug ("File name set as Title:" + bookTitle);
        }
        //determine the author of the book
        if (OpfContents.contains ("<dc:creator") && OpfContents.contains ("</dc:creator>")) {
            int startOfAuthorText = OpfContents.index_of (">", OpfContents.index_of ("<dc:creator"));
            int endOfAuthorText = OpfContents.index_of ("</dc:creator>", startOfAuthorText);
            if (startOfAuthorText != -1 && endOfAuthorText != -1 && endOfAuthorText > startOfAuthorText) {
                string bookAuthor = BookwormApp.Utils.decodeHTMLChars (OpfContents.slice (startOfAuthorText + 1, endOfAuthorText));
                aBook.setBookAuthor (bookAuthor);
                debug ("Determined eBook Author as:" + bookAuthor);
            } else {
                aBook.setBookAuthor (BookwormApp.Constants.TEXT_FOR_UNKNOWN_TITLE);
                debug ("Could not determine eBook Author, default Author set");
            }
        } else {
            aBook.setBookAuthor (BookwormApp.Constants.TEXT_FOR_UNKNOWN_TITLE);
            debug ("Could not determine eBook Author, default title set");
        }
        info ("[END] [FUNCTION:setBookMetaData]");
        return aBook;
    }
}
