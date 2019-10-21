/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and is used for parsing FB2 file formats
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
* ++
* You should have received a copy of the GNU General Public License along
* with Bookworm. If not, see http://www.gnu.org/licenses/.
*/

using Gee;
using GLib;
using Gdk;
public class BookwormApp.fb2Reader {
    //this location will be used for .fb2 and also for extracted .fb2 from .fb2.zip
    public static string fb2_location = "";

    public static BookwormApp.Book parseFictionBook (owned BookwormApp.Book aBook) {
        info ("[START] [FUNCTION:parseFictionBook] book.location=" + aBook.getBookLocation ());
        //Only parse the eBook if it has not been parsed already
        if (!aBook.getIsBookParsed ()) {
            debug ("Starting to parse FB2 Book located at:" + aBook.getBookLocation ());
            //Extract the contents of the FB2
            aBook = extractEBook (aBook);
            if ("false" == aBook.getBookExtractionLocation ()) { //handle error condition
                aBook.setIsBookParsed (false);
                aBook.setParsingIssue (BookwormApp.Constants.TEXT_FOR_EXTRACTION_ISSUE);
                return aBook;
            }
            //Check if content from FB2 file is populated as HTML files
            if (aBook.getBookContentList ().size < 1) {
                aBook.setIsBookParsed (false);
                aBook.setParsingIssue (BookwormApp.Constants.TEXT_FOR_CONTENT_ISSUE);
                return aBook;
            }
            //Determine Book Cover Image if it is not already available
            if (!aBook.getIsBookCoverImagePresent ()) {
                aBook = setCoverImage (aBook);
            }
            //Determine Book Meta Data like Title, Author, etc
            aBook = setBookMetaData (aBook);
            aBook.setIsBookParsed (true);
        }
        info ("[END] [FUNCTION:parseEPubBook]");
        return aBook;
    }

    public static bool isFB2Format (string eBookLocation) {
        info ("[START] [FUNCTION:isFB2Format] extractionLocation=" + eBookLocation);
        bool fb2Format = false;
        ArrayList<XMLData> inputDataList = new ArrayList<XMLData> ();
        inputDataList.add (
        new XMLData () {
            containerTagName = "FictionBook",
            inputTagName = "body",
            inputAttributeName="",
            isXMLExtraction = true
        });
        XmlParser thisParser = new XmlParser ();
        ArrayList<XMLData> extractedDataList = new ArrayList<XMLData> ();
        extractedDataList = thisParser.extractDataFromXML (eBookLocation, inputDataList);
        if (extractedDataList.size > 0) {
            fb2Format = true;
        }
        if (!fb2Format) {
            warning ("Error while checking format of FB2 file [" + eBookLocation + "], tag name \"FictionBook\" not found");
        }
        info ("[END] [FUNCTION:isFB2Format] fb2Format check:" + fb2Format.to_string ());
        return fb2Format;
    }

    public static BookwormApp.Book extractEBook (owned BookwormApp.Book aBook) {
        info ("[START] [FUNCTION:extractEBook] : " + aBook.to_string ());
        string extractionLocation = "false";
        string status = "false";
        fb2_location = aBook.getBookLocation ();
        //create a location for extraction of eBook based on local storage prefference
        if (BookwormApp.Bookworm.settings == null) {
            BookwormApp.Bookworm.settings = BookwormApp.Settings.get_instance ();
        }
        if (BookwormApp.Bookworm.settings.is_local_storage_enabled) {
            extractionLocation = BookwormApp.Bookworm.bookworm_config_path + 
            "/books/" + File.new_for_path (fb2_location).get_basename ();
        } else {
            extractionLocation = BookwormApp.Constants.EBOOK_EXTRACTION_LOCATION + 
            File.new_for_path (fb2_location).get_basename ();
        }
        debug ("Based on caching preference, the extraction location determined as:" + extractionLocation);
        //check and create directory for extracting contents of ebook
        BookwormApp.Utils.fileOperations ("CREATEDIR", extractionLocation, "", "");
        debug ("Directory created for extraction location:" + extractionLocation);
        aBook.setBookExtractionLocation (extractionLocation);
        if ("false" == extractionLocation) {
            warning ("Failure in determining extraction location for FB2 file [" + fb2_location + "]");
            aBook.setBookExtractionLocation ("false");
            return aBook;
        }
        //handle the case if the FB2 file is in a zip container
        if (fb2_location.up ().last_index_of (".FB2.ZIP") != -1) {
            //unzip the contents to extraction location
            string unzip_status = BookwormApp.Utils.execute_sync_command (
                "unzip -o \"" + fb2_location + "\" -d \"" + extractionLocation + "\"");
            if ("false" == unzip_status) {
                //decompress of FB2 from ZIP failed
                aBook.setIsBookParsed (false);
                aBook.setParsingIssue (BookwormApp.Constants.TEXT_FOR_CONTENT_ISSUE);
                return aBook;
            } else {
                //sucessfully decompressed FB2 from ZIP, set fb2 location to extracted FB2 file
                fb2_location = BookwormApp.Utils.getFullPathFromFilename (extractionLocation, "*.fb2");
            }
        }
        //Check header of FB2 XML content to ensure FictionBook header tag
        if (!isFB2Format (fb2_location)) {
            aBook.setIsBookParsed (false);
            aBook.setParsingIssue (BookwormApp.Constants.TEXT_FOR_CONTENT_ISSUE);
            return aBook;
        }
        //Extract to HTML by fetching the text from the <body><section>
        ArrayList<XMLData> inputDataList = new ArrayList<XMLData> ();
        inputDataList.add (new XMLData () {
            containerTagName = "body",
            inputTagName = "section",
            inputAttributeName="",
            isXMLExtraction = true
        });
        XmlParser thisParser = new XmlParser ();
        ArrayList<XMLData> extractedDataList = new ArrayList<XMLData> ();
        extractedDataList = thisParser.extractDataFromXML (fb2_location, inputDataList);
        debug ("No. of sections found in FB2 file:" + (extractedDataList.size).to_string ());
        //Write the extracted text into html files
        int filecount = 1;
        foreach (XMLData aExtractedData in extractedDataList) {
            foreach (string aTagValue in aExtractedData.extractedTagValues) {
                string filename = File.new_for_path (fb2_location).get_basename () + "_" + filecount.to_string () + ".html";
                status = BookwormApp.Utils.fileOperations (
                    "WRITE", extractionLocation, filename, "<html><body>" + aTagValue + "</body></html>");
                filecount = filecount + 1;
                if ("true" == status) {
                    aBook.setBookContentList ( extractionLocation + "/" + filename);
                    debug ("Extracted contents written to file:" + extractionLocation + "/" + filename);
                }
            }
        }
        string baseLocationOfContents = extractionLocation;
        aBook.setBaseLocationOfContents (baseLocationOfContents);
        debug ("Base location for FB2 extracted contents:" + baseLocationOfContents);
        //check if extracted contents were written to html files
        if (aBook.getBookContentList ().size < 1) {
            warning ("Failure in extracting contents of FB2 file [" + fb2_location + "]");
            aBook.setBookExtractionLocation ("false");
            return aBook;
        }
        info ("[END] [FUNCTION:extractEBook] FB2 book extracted successfully at location:" + aBook.getBookExtractionLocation ());
        return aBook;
    }

    public static BookwormApp.Book setCoverImage (owned BookwormApp.Book aBook) {
        info ("[START] [FUNCTION:setCoverImage] book.location=" + aBook.getBookLocation ());
        string bookCoverLocation = "";
        //set up the meta data to get images from base64 encoded data
        ArrayList<XMLData> inputDataList = new ArrayList<XMLData> ();
        inputDataList.add (new XMLData () {
            containerTagName = "FictionBook",
            inputTagName = "binary",
            inputAttributeName="id"
        });
        inputDataList.add (new XMLData () {
            containerTagName = "FictionBook",
            inputTagName = "binary",
            inputAttributeName="content-type"
        });
        XmlParser thisParser = new XmlParser ();
        ArrayList<XMLData> extractedDataList = new ArrayList<XMLData> ();
        extractedDataList = thisParser.extractDataFromXML (fb2_location, inputDataList);
        ArrayList<string> image_id = new ArrayList<string> ();
        ArrayList<string> image_type = new ArrayList<string> ();
        //loop through the number of queries i.e. 2
        for (int i = 0; i < 2; i++) {
            //loop through the attributes twice - image_id and image type. Collect in seperate arrays
            int number_of_extracted_images = extractedDataList[i].extractedTagAttributes.size;
            debug ("Size of binary tags=" + number_of_extracted_images.to_string ());
            for (int j = 0; j < number_of_extracted_images; j++) {
                string aAttributeValue = extractedDataList[i].extractedTagAttributes[j];
                if (aAttributeValue.contains ("image/")) {
                    image_type.add (aAttributeValue.replace ("image/",""));
                    debug ("Image Type determined as:" + image_type[image_type.size - 1]);
                } else {
                    //attribute is the image id
                    image_id.add (aAttributeValue);
                    debug ("Image Id determined as:" + image_id[image_id.size - 1]);
                }
            }
        }
        //loop through the tag values and write the base64 image data to files
        for (int i = 0; i < image_id.size; i++) {
            string encoded_image_data = extractedDataList[0].extractedTagValues[i];
            if (encoded_image_data.length > 0) {
                debug ("Found encoded image data:" + encoded_image_data.substring (0,20));
                uchar[] data = Base64.decode (encoded_image_data);
                MemoryInputStream mis = new MemoryInputStream.from_data (data);
                Pixbuf pixbuf = new Pixbuf.from_stream (mis);
                string image_location = aBook.getBookExtractionLocation () + "/" + image_id[i];
                try {
                    pixbuf.save (image_location, image_type[i]);
                    //assign the first image for the cover temporarily
                    if (bookCoverLocation.length < 1) {
                        bookCoverLocation = image_location;
                        debug ("Assigning the first image as cover image:" + bookCoverLocation);
                    }
                } catch (Error e) {
                    warning ("Failure in writting decoded image data in FB2 file [" +
                        aBook.getBookLocation () + "]: " + e.message);
                }
            }
        }
        //set up the meta data to get information o the cover image
        inputDataList = new ArrayList<XMLData> ();
        inputDataList.add (new XMLData () {
            containerTagName = "",
            inputTagName = "coverpage",
            inputAttributeName="",
            isXMLExtraction = true
        });
        thisParser = new XmlParser ();
        extractedDataList = new ArrayList<XMLData> ();
        extractedDataList = thisParser.extractDataFromXML (fb2_location, inputDataList);
        debug ("Number of results for coverpage image XML query:" + extractedDataList.size.to_string ());
        if (extractedDataList.size > 0 && extractedDataList[0].extractedTagValues.size > 0) {
            string name_of_cover_image = BookwormApp.Utils.decodeHTMLChars (extractedDataList[0].extractedTagValues[0]);
            debug ("Results of cover page query:" + name_of_cover_image);
            if (name_of_cover_image.length > 1 && (name_of_cover_image.split (" ")).length > 1) {
                for (int i = 0; i < (name_of_cover_image.split (" ")).length; i++) {
                    if (name_of_cover_image.split (" ") [i].contains ("href") && (i< (name_of_cover_image.split (" ")).length)) {
                        name_of_cover_image = name_of_cover_image.split (" ") [i + 1];
                        name_of_cover_image = name_of_cover_image.replace ("#","").replace (">","").strip ();
                        debug ("Determined cover image name as:" + name_of_cover_image);
                        for (i = 0; i < BookwormApp.Constants.FILE_CHOOSER_FILTER_IMAGES.length; i++) {
                            //check if the image is a known file type
                            debug ("Checking if cover image is of type:" + BookwormApp.Constants.FILE_CHOOSER_FILTER_IMAGES[i]);
                            if (name_of_cover_image.contains (BookwormApp.Constants.FILE_CHOOSER_FILTER_IMAGES[i].replace ("*",""))) {
                                debug ("Determined cover image as:" + name_of_cover_image);
                                bookCoverLocation = BookwormApp.Utils.getFullPathFromFilename (
                                    aBook.getBookExtractionLocation (), name_of_cover_image);
                                debug ("Overriding image location to:" + bookCoverLocation);
                                break;
                            }
                        }
                    }
                }
            }
        }
        //check if cover was not found and assign flag for default cover to be used
        if (bookCoverLocation.length < 1 || bookCoverLocation == "") {
            aBook.setIsBookCoverImagePresent (false);
            debug ("Cover image not found for book located at:" + aBook.getBookExtractionLocation ());
        } else {
            //copy cover image to bookworm cover image cache
            aBook = BookwormApp.Utils.setBookCoverImage (aBook, bookCoverLocation);
        }
        info ("[END] [FUNCTION:setCoverImage] book.location=" + aBook.getBookLocation () + ", bookCoverLocation=" + bookCoverLocation);
        return aBook;
    }

    public static BookwormApp.Book setBookMetaData (owned BookwormApp.Book aBook) {
        info ("[START] [FUNCTION:setBookMetaData] book.location=" + aBook.getBookLocation ());
        //set defaults and then over-ride with extracted data if found
        aBook.setBookAuthor (BookwormApp.Constants.TEXT_FOR_UNKNOWN_TITLE);
        aBook.setBookTitle (BookwormApp.Constants.TEXT_FOR_UNKNOWN_TITLE);
        //Set up XML queries for extracting meta data from FB2 XML
        ArrayList<XMLData> inputDataList = new ArrayList<XMLData> ();
        inputDataList.add (new XMLData () {
            containerTagName = "author",
            inputTagName = "first-name",
            inputAttributeName=""
        });
        inputDataList.add (new XMLData () {
            containerTagName = "author",
            inputTagName = "last-name",
            inputAttributeName=""
        });
        inputDataList.add (new XMLData () {
            containerTagName = "description",
            inputTagName = "book-title",
            inputAttributeName=""
        });
        XmlParser thisParser = new XmlParser ();
        ArrayList<XMLData> extractedDataList = new ArrayList<XMLData> ();
        extractedDataList = thisParser.extractDataFromXML (fb2_location, inputDataList);
        //set the author first name
        if (extractedDataList.size > 0 && extractedDataList[0].extractedTagValues.size > 0) {
            aBook.setBookAuthor (BookwormApp.Utils.decodeHTMLChars (extractedDataList[0].extractedTagValues[0]));
        }
        //add the author last name
        if (extractedDataList.size > 1 && extractedDataList[1].extractedTagValues.size > 0) {
            aBook.setBookAuthor (aBook.getBookAuthor () + " " +
                BookwormApp.Utils.decodeHTMLChars (extractedDataList[1].extractedTagValues[0]));
        }
        //set the title of the book
        if (extractedDataList.size > 2 && extractedDataList[2].extractedTagValues.size > 0) {
            aBook.setBookTitle (BookwormApp.Utils.decodeHTMLChars (extractedDataList[2].extractedTagValues[0]));
        }
        info ("[END] [FUNCTION:setBookMetaData] Determined author[" + aBook.getBookAuthor () + "] and title[" + aBook.getBookTitle () + "]");
        return aBook;
    }
}
