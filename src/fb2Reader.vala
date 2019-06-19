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
*
* You should have received a copy of the GNU General Public License along
* with Bookworm. If not, see http://www.gnu.org/licenses/.
*/

using Gee;
public class BookwormApp.fb2Reader {
  public static BookwormApp.Book parseFictionBook (owned BookwormApp.Book aBook) {
    info("[START] [FUNCTION:parseFictionBook] book.location="+aBook.getBookLocation());
    //Only parse the eBook if it has not been parsed already
    if(!aBook.getIsBookParsed()){
    debug ("Starting to parse FB2 Book located at:"+aBook.getBookLocation());
      //Check header of FB2 XML content to ensure FictionBook header tag
      if(!isFB2Format(aBook)){
        aBook.setIsBookParsed(false);
        aBook.setParsingIssue(BookwormApp.Constants.TEXT_FOR_CONTENT_ISSUE);
        return aBook;
      }
      //Extract the contents of the FB2
      aBook = extractEBook(aBook);
      if("false" == aBook.getBookExtractionLocation()){ //handle error condition
        aBook.setIsBookParsed(false);
        aBook.setParsingIssue(BookwormApp.Constants.TEXT_FOR_EXTRACTION_ISSUE);
        return aBook;
      }

      //Check if content from FB2 file is populated as HTML files
      if(aBook.getBookContentList().size < 1){
        aBook.setIsBookParsed(false);
        aBook.setParsingIssue(BookwormApp.Constants.TEXT_FOR_CONTENT_ISSUE);
        return aBook;
      }

      //Determine Book Cover Image if it is not already available
      if(!aBook.getIsBookCoverImagePresent()){
        aBook = setCoverImage(aBook);
      }

      //Determine Book Meta Data like Title, Author, etc
      aBook = setBookMetaData(aBook);

      aBook.setIsBookParsed(true);

    }
    info("[END] [FUNCTION:parseEPubBook]");
    return aBook;
  }

  public static bool isFB2Format (BookwormApp.Book aBook){
        info("[START] [FUNCTION:isFB2Format] extractionLocation="+aBook.getBookLocation());
        bool fb2Format = false;
        string eBookLocation = "";
        try{
            eBookLocation = aBook.getBookLocation();
            ArrayList<XMLData> inputDataList = new ArrayList<XMLData>();
            inputDataList.add(
                new XMLData() {
                                containerTagName = "FictionBook",
                                inputTagName = "body",
                                inputAttributeName="",
                                isXMLExtraction = true
                }
            );
            XmlParser thisParser = new XmlParser();
            ArrayList<XMLData> extractedDataList = new ArrayList<XMLData>();
            extractedDataList = thisParser.extractDataFromXML(eBookLocation, inputDataList);
            if(extractedDataList.size > 0){
                fb2Format = true;
            }
        }catch (Error e){
            warning ("Error while checking format of FB2 file ["+eBookLocation+"]:"+e.message);
        }

        info("[END] [FUNCTION:isFB2Format] fb2Format check:"+fb2Format.to_string());
        return fb2Format;
  }

  public static BookwormApp.Book extractEBook(owned BookwormApp.Book aBook){
        info("[START] [FUNCTION:extractEBook] : "+aBook.to_string());
        string extractionLocation = "false";
        string status = "false";
        string eBookLocation = "";
        try{
            eBookLocation = aBook.getBookLocation();
            //create a location for extraction of eBook based on local storage prefference
            if(BookwormApp.Bookworm.settings == null){
                BookwormApp.Bookworm.settings = BookwormApp.Settings.get_instance();
            }
            if(BookwormApp.Bookworm.settings.is_local_storage_enabled){
                extractionLocation = BookwormApp.Bookworm.bookworm_config_path + 
                                        "/books/" + 
                                        File.new_for_path(eBookLocation).get_basename();
            }else{
                extractionLocation = BookwormApp.Constants.EBOOK_EXTRACTION_LOCATION + 
                                     File.new_for_path(eBookLocation).get_basename();
            }
            debug("Based on caching preference, the extraction location determined as:"+extractionLocation);
            //check and create directory for extracting contents of ebook
            BookwormApp.Utils.fileOperations("CREATEDIR", extractionLocation, "", "");
            debug ("Directory created for extraction location:"+extractionLocation);
            aBook.setBookExtractionLocation(extractionLocation);
        }catch (Error e){
            warning("Failure in determining extraction location for FB2 file ["+eBookLocation+"]:"+e.message);
            aBook.setBookExtractionLocation("false");
        }
        try{
            //Fetch the text from the <body><section>
            ArrayList<XMLData> inputDataList = new ArrayList<XMLData>();
            inputDataList.add(
                new XMLData() {
                                containerTagName = "body",
                                inputTagName = "section",
                                inputAttributeName="",
                                isXMLExtraction = true
                }
            );
            XmlParser thisParser = new XmlParser();
            ArrayList<XMLData> extractedDataList = new ArrayList<XMLData>();
            extractedDataList = thisParser.extractDataFromXML(eBookLocation, inputDataList);
            debug("No. of sections found in FB2 file:"+(extractedDataList.size).to_string());
            //Write the extracted text into html files
            int filecount = 1;
            foreach(XMLData aExtractedData in extractedDataList){
                foreach(string aTagValue in aExtractedData.extractedTagValues){
                    string filename = File.new_for_path(eBookLocation).get_basename() + "_" + filecount.to_string() + ".html";
                    status = BookwormApp.Utils.fileOperations (
                                "WRITE", 
                                extractionLocation, 
                                filename, 
                                "<html><body>"+aTagValue+"</body></html>"
                            );
                    filecount = filecount + 1;
                    aBook.setBookContentList( extractionLocation + "/" + filename);
                    debug ("Extracted contents written to file:"+ extractionLocation + "/" + filename);
                }
            }
            string baseLocationOfContents = extractionLocation;
            aBook.setBaseLocationOfContents(baseLocationOfContents);
            debug("Base location for FB2 extracted contents:"+baseLocationOfContents);
        }catch (Error e){
            warning("Failure in extracting contents of FB2 file ["+eBookLocation+"]:"+e.message);
            aBook.setBookExtractionLocation("false");
        }
        info("[END] [FUNCTION:extractEBook] extractionLocation="+aBook.getBookExtractionLocation());
        return aBook;
  }

  public static BookwormApp.Book setCoverImage (owned BookwormApp.Book aBook){
    info("[START] [FUNCTION:setCoverImage] book.location="+aBook.getBookLocation());
    string bookCoverLocation = "";


    //check if cover was still not found and assign flag for default cover to be used
    if( bookCoverLocation.length < 1 &&
        "true" == BookwormApp.Utils.fileOperations ("EXISTS", "", bookCoverLocation, "") )
    {
        aBook.setIsBookCoverImagePresent(false);
        debug("Cover image not found for book located at:"+aBook.getBookExtractionLocation());
    } else{
        //copy cover image to bookworm cover image cache
        aBook = BookwormApp.Utils.setBookCoverImage(aBook, bookCoverLocation);
    }
    info("[END] [FUNCTION:setCoverImage] book.location="+aBook.getBookLocation()+", bookCoverLocation="+bookCoverLocation);
    return aBook;
  }

  public static BookwormApp.Book setBookMetaData(owned BookwormApp.Book aBook){
    info("[START] [FUNCTION:setBookMetaData] book.location="+aBook.getBookLocation());
    //set defaults and then over-ride with extracted data if found
    aBook.setBookAuthor(BookwormApp.Constants.TEXT_FOR_UNKNOWN_TITLE);
    aBook.setBookTitle(BookwormApp.Constants.TEXT_FOR_UNKNOWN_TITLE);

    //Set up XML queries for extracting meta data from FB2 XML
    ArrayList<XMLData> inputDataList = new ArrayList<XMLData>();
    inputDataList.add(
        new XMLData() {
                        containerTagName = "author",
                        inputTagName = "first-name",
                        inputAttributeName=""
        }
    );
    inputDataList.add(
        new XMLData() {
                        containerTagName = "author",
                        inputTagName = "last-name",
                        inputAttributeName=""
        }
    );
    inputDataList.add(
        new XMLData() {
                        containerTagName = "description",
                        inputTagName = "book-title",
                        inputAttributeName=""
        }
    );
    XmlParser thisParser = new XmlParser();
    ArrayList<XMLData> extractedDataList = new ArrayList<XMLData>();
    extractedDataList = thisParser.extractDataFromXML(aBook.getBookLocation(), inputDataList);
    if(extractedDataList.size > 0 && extractedDataList[0].extractedTagValues.size > 0){
        aBook.setBookAuthor(BookwormApp.Utils.decodeHTMLChars(extractedDataList[0].extractedTagValues[0]));
    }
    if(extractedDataList.size > 1 && extractedDataList[1].extractedTagValues.size > 0){
        aBook.setBookAuthor(
            aBook.getBookAuthor() + " " +
            BookwormApp.Utils.decodeHTMLChars(extractedDataList[1].extractedTagValues[0]));
    }
    if(extractedDataList.size > 2 && extractedDataList[2].extractedTagValues.size > 0){
        aBook.setBookTitle(BookwormApp.Utils.decodeHTMLChars(extractedDataList[2].extractedTagValues[0]));
    }
    info("[END] [FUNCTION:setBookMetaData] Determined author["+aBook.getBookAuthor()+"] and title["+aBook.getBookTitle()+"]");
    return aBook;
  }
}
