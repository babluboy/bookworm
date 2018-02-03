/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and is used for parsing EPUB file formats
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
public class BookwormApp.ePubReader {

  public static string NCXRefInSpineData = "";
  public static BookwormApp.Book parseEPubBook (owned BookwormApp.Book aBook){
    //Only parse the eBook if it has not been parsed already
    if(!aBook.getIsBookParsed()){
      debug ("Starting to parse EPub Book located at:"+aBook.getBookLocation());
      //Extract the content of the EPub
      string extractionLocation = extractEBook(aBook.getBookLocation());
      if("false" == extractionLocation){ //handle error condition
        aBook.setIsBookParsed(false);
        aBook.setParsingIssue(BookwormApp.Constants.TEXT_FOR_EXTRACTION_ISSUE);
        return aBook;
      }else{
        aBook.setBookExtractionLocation(extractionLocation);
      }
      //Check if the EPUB mime type is correct
      bool isEPubFormat = isEPubFormat(extractionLocation);
      if(!isEPubFormat){ //handle error condition
        aBook.setIsBookParsed(false);
        aBook.setParsingIssue(BookwormApp.Constants.TEXT_FOR_MIMETYPE_ISSUE);
        return aBook;
      }
      //Determine the location of OPF File
      string locationOfOPFFile = getOPFFileLocation(extractionLocation);
      if("false" == locationOfOPFFile){ //handle error condition
        aBook.setIsBookParsed(false);
        aBook.setParsingIssue(BookwormApp.Constants.TEXT_FOR_CONTENT_ISSUE);
        return aBook;
      }
      string baseLocationOfContents = locationOfOPFFile.replace(File.new_for_path(locationOfOPFFile).get_basename(), "");
      aBook.setBaseLocationOfContents(baseLocationOfContents);

      //Populate content list for EPub Book
      aBook = determineToC(aBook, locationOfOPFFile);
      if(aBook.getBookContentList().size < 1){
        aBook.setIsBookParsed(false);
        aBook.setParsingIssue(BookwormApp.Constants.TEXT_FOR_CONTENT_ISSUE);
        return aBook;
      }

      //Try to determine Book Cover Image if it is not already available
      if(!aBook.getIsBookCoverImagePresent()){
        aBook = setCoverImage(aBook, locationOfOPFFile);
      }

      //Determine Book Meta Data like Title, Author, etc
      aBook = setBookMetaData(aBook, locationOfOPFFile);

      aBook.setIsBookParsed(true);
      debug ("Sucessfully parsed EPub Book located at:"+aBook.getBookLocation());
    }
    return aBook;
  }

  public static string extractEBook(string eBookLocation){
        string extractionLocation = "false";
        debug("Initiated process for content extraction of ePub Book located at:"+eBookLocation);
        //create a location for extraction of eBook based on local storage prefference
        if(BookwormApp.Bookworm.settings == null){
            BookwormApp.Bookworm.settings = BookwormApp.Settings.get_instance();
        }
        if(BookwormApp.Bookworm.settings.is_local_storage_enabled){
            extractionLocation = BookwormApp.Bookworm.bookworm_config_path + "/books/" + File.new_for_path(eBookLocation).get_basename();
        }else{
            extractionLocation = BookwormApp.Constants.EBOOK_EXTRACTION_LOCATION + File.new_for_path(eBookLocation).get_basename();
        }
        //check and create directory for extracting contents of ebook
        BookwormApp.Utils.fileOperations("CREATEDIR", extractionLocation, "", "");
        //unzip eBook contents into extraction location
        BookwormApp.Utils.execute_sync_command("unzip -o \"" + eBookLocation + "\" -d \""+ extractionLocation +"\"");
        debug("eBook contents extracted sucessfully into location:"+extractionLocation);
        return extractionLocation;
  }

  public static bool isEPubFormat (string extractionLocation){
        bool ePubFormat = false;
        debug("Checking if mime type is valid ePub for contents at:"+extractionLocation);
        string ePubMimeContents = BookwormApp.Utils.fileOperations(
                                                                "READ", 
                                                                extractionLocation, 
                                                                BookwormApp.Constants.EPUB_MIME_SPECIFICATION_FILENAME, 
                                                                "");
        if("false" == ePubMimeContents){
            //Mime Content File was not found at expected location
            warning("Mime Content file could not be located at expected location:"+
                            extractionLocation+"/"+
                            BookwormApp.Constants.EPUB_MIME_SPECIFICATION_FILENAME);
            return false;
        }
        debug(  "Mime Contents found in file :"+
                        extractionLocation+"/"+
                        BookwormApp.Constants.EPUB_MIME_SPECIFICATION_FILENAME+
                        " is:"+ ePubMimeContents);
        if(ePubMimeContents.strip() != BookwormApp.Constants.EPUB_MIME_SPECIFICATION_CONTENT){
            debug(  "Mime Contents in file :"+extractionLocation+"/"+
                            BookwormApp.Constants.EPUB_MIME_SPECIFICATION_FILENAME+" is not :"+
                            BookwormApp.Constants.EPUB_MIME_SPECIFICATION_CONTENT+". No further parsing will be done.");
            return false;
        }else{
            //mime content is as expected
            ePubFormat = true;
        }
        debug("Sucessfully validated MIME type....");
        return ePubFormat;
  }

  public static string getOPFFileLocation(string extractionLocation){
        string locationOfOPFFile = "false";
        //Form the path to the META-INF/container.xml file
        string pathToXMLFile = extractionLocation+"/"+BookwormApp.Constants.EPUB_META_INF_FILENAME;
        //Parse META-INF/container.xml file to locate the path to the OPF file
        ArrayList<XMLData> inputDataList = new ArrayList<XMLData>();
        inputDataList.add(new XMLData() {
                                            containerTagName = "rootfiles",
                                            inputTagName = "rootfile",
                                            inputAttributeName = "full-path"}
                                        );
        XmlParser thisParser = new XmlParser();
        ArrayList<XMLData> extractedDataList = new ArrayList<XMLData>();
        extractedDataList = thisParser.extractDataFromXML(pathToXMLFile, inputDataList);

        foreach(XMLData aExtractedData in extractedDataList){
           foreach(string aAttributeValue in aExtractedData.extractedTagAttributes){
                string  OPFFilePath = aAttributeValue;
                locationOfOPFFile = extractionLocation + "/" + OPFFilePath;
            }
        }
        debug ("Sucessfully determined absolute path to OPF File as : "+locationOfOPFFile);
        return locationOfOPFFile;
  }

  public static ArrayList<XMLData> parseOPFData (string locationOfOPFFile) {
        //Parse OPF xml file to read the MANIFEST data (id, href, media-type)
        ArrayList<XMLData> inputDataList = new ArrayList<XMLData>();
        inputDataList.add(new XMLData() {
                                            containerTagName = "manifest",
                                            inputTagName = "item",
                                            inputAttributeName = "id"}
                                        );
        inputDataList.add(new XMLData() {
                                            containerTagName = "manifest",
                                            inputTagName = "item",
                                            inputAttributeName ="href"}
                                        );
        inputDataList.add(new XMLData() {
                                            containerTagName = "manifest",
                                            inputTagName = "item",
                                            inputAttributeName ="media-type"}
                                        );
        inputDataList.add(new XMLData() {
                                        containerTagName = "spine",
                                        inputTagName = "itemref",
                                        inputAttributeName ="idref"}
                                    );
        inputDataList.add(new XMLData() {
                                        containerTagName = "",
                                        inputTagName = "spine",
                                        inputAttributeName ="toc"}
                                    );
        XmlParser thisParser = new XmlParser();
        ArrayList<XMLData> opfItemsList = new ArrayList<XMLData>();
        opfItemsList = thisParser.extractDataFromXML(locationOfOPFFile, inputDataList);
        return opfItemsList;
  }
   
  public static BookwormApp.Book determineToC (owned BookwormApp.Book aBook, string locationOfOPFFile) {
    //Parse OPF xml file to read the MANIFEST data (id, href, media-type)
    ArrayList<XMLData> inputDataList = new ArrayList<XMLData>();
    inputDataList.add(new XMLData() {
                                        containerTagName = "manifest",
                                        inputTagName = "item",
                                        inputAttributeName = "id"}
                                    );
    inputDataList.add(new XMLData() {
                                        containerTagName = "manifest",
                                        inputTagName = "item",
                                        inputAttributeName = "href"}
                                    );
    inputDataList.add(new XMLData() {
                                        containerTagName = "manifest",
                                        inputTagName = "item",
                                        inputAttributeName = "media-type"}
                                    );
    inputDataList.add(new XMLData() {
                                    containerTagName = "spine",
                                    inputTagName = "itemref",
                                    inputAttributeName = "idref"}
                                );
    inputDataList.add(new XMLData() {
                                    containerTagName = "",
                                    inputTagName = "spine",
                                    inputAttributeName = "toc"}
                                );
    XmlParser thisParser = new XmlParser();
    ArrayList<XMLData> opfItemsList = new ArrayList<XMLData>();
    opfItemsList = thisParser.extractDataFromXML(locationOfOPFFile, inputDataList);

    if(opfItemsList.size>3 && opfItemsList.get(4).extractedTagAttributes.size>0){
        debug("Sucessfully extracted SPINE data..");
        //Get the reference of the NCX file in the SPINE data
        string spineNCXReference = opfItemsList.get(4).extractedTagAttributes.get(0);
        debug("Sucessfully determined NCX File Reference as:"+spineNCXReference);
        //Get the position of NCX Reference in MANIFEST data
        if(opfItemsList.size>0 && opfItemsList.get(0).extractedTagAttributes.contains(spineNCXReference)){
            debug("Sucessfully extracted MANIFEST data..");
            int spineNCXPosition = opfItemsList.get(0).extractedTagAttributes.index_of(spineNCXReference);
            debug("Sucessfully matched NCX File path information on MANIFEST data at position:"+spineNCXPosition.to_string());
            //Get the location of the NCX file from the MANIFEST href attribute
            string NCXFileRelativePath = opfItemsList.get(1).extractedTagAttributes.get(spineNCXPosition);
            debug("Extracted relative NCX file path from MANIFEST data as:"+ NCXFileRelativePath);
            string ncxFilePath = (   BookwormApp.Utils.getFullPathFromFilename (
                                                            aBook.getBaseLocationOfContents(), NCXFileRelativePath.strip()
                                                      )
                                                 ).strip();
            if("true" == BookwormApp.Utils.fileOperations ("EXISTS", "", ncxFilePath, "")){
                debug("Sucessfully determined NCX File Path as:"+ncxFilePath);
                //Parse NCX xml file to read the ToC data (id, href, media-type)
                ArrayList<XMLData> inputDataListForToC = new ArrayList<XMLData>();
                inputDataListForToC.add(new XMLData() {
                                    containerTagName = "navLabel",
                                    inputTagName = "text",
                                    inputAttributeName = ""}
                                );
                inputDataListForToC.add(new XMLData() {
                                    containerTagName = "",
                                    inputTagName = "content",
                                    inputAttributeName = "src"}
                                );
                XmlParser ncxParser = new XmlParser();
                ArrayList<XMLData> ncxDataExtractedList = new ArrayList<XMLData>();
                ncxDataExtractedList = ncxParser.extractDataFromXML(ncxFilePath, inputDataListForToC);
                if( ncxDataExtractedList.get(0).extractedTagValues.size > 0 &&
                    ncxDataExtractedList.get(1).extractedTagAttributes.size > 0 &&
                    ncxDataExtractedList.get(0).extractedTagValues.size == ncxDataExtractedList.get(1).extractedTagAttributes.size)
                {
                    for(int count=0; count<ncxDataExtractedList.get(0).extractedTagValues.size; count++){
                        HashMap<string,string> TOCMapItem = new HashMap<string,string>();
                        string tocLocation = ncxDataExtractedList.get(1).extractedTagAttributes.get(count);
                        if( tocLocation.index_of("#") != -1 ){
                            tocLocation = tocLocation.slice(0, tocLocation.index_of("#"));
                        }
                        tocLocation = BookwormApp.Utils.getFullPathFromFilename(aBook.getBaseLocationOfContents(), tocLocation);
                        TOCMapItem.set(tocLocation, ncxDataExtractedList.get(0).extractedTagValues.get(count));
                        aBook.setTOC(TOCMapItem);
                        debug("Extracted ToC Chapter Name:"+
                                                    ncxDataExtractedList.get(0).extractedTagValues.get(count)+
                                    " at location:"+
                                                    ncxDataExtractedList.get(1).extractedTagAttributes.get(count));
                    }
                }
            }
        }
    }
    
    // Create the content list  - clear the content list of any previous items
    aBook.clearBookContentList();
    //loop over all idref attributes in spine data
    foreach(string spineIDREF in opfItemsList[3].extractedTagAttributes){
        //check if the SPINE IDREF exists in the MANIFEST Attributes
        if(opfItemsList[0].extractedTagAttributes.contains(spineIDREF)){
            int positionOfIDREF = opfItemsList[0].extractedTagAttributes.index_of (spineIDREF);
            //extract the HREF from MANIFEST corresponding to the SPINE IDREF
            string locationOfContentData = opfItemsList[1].extractedTagAttributes.get(positionOfIDREF);
            aBook.setBookContentList(aBook.getBaseLocationOfContents()+locationOfContentData);
            debug("Book content data :"+aBook.getBaseLocationOfContents()+locationOfContentData);
        }
    }
    return aBook;
  }

  public static BookwormApp.Book setCoverImage (owned BookwormApp.Book aBook, string locationOfOPFFile){
    debug("Initiated process for cover image extraction of eBook located at:"+aBook.getBookExtractionLocation());
    string bookCoverLocation = "";
    //Parse OPF xml file to read the MANIFEST data (id, href, media-type)
    ArrayList<XMLData> inputDataList = new ArrayList<XMLData>();
    inputDataList.add(new XMLData() {
                                        containerTagName = "manifest",
                                        inputTagName = "item",
                                        inputAttributeName = "id"}
                                    );
    inputDataList.add(new XMLData() {
                                        containerTagName = "manifest",
                                        inputTagName = "item",
                                        inputAttributeName = "media-type"}
                                    );
    inputDataList.add(new XMLData() {
                                        containerTagName = "manifest",
                                        inputTagName = "item",
                                        inputAttributeName = "href"}
                                    );
    XmlParser thisParser = new XmlParser();
    ArrayList<XMLData> opfItemsList = new ArrayList<XMLData>();
    opfItemsList = thisParser.extractDataFromXML(locationOfOPFFile, inputDataList);
    
    //Check for a MANIFEST item for cover
    int count = 0;
    foreach(string id in opfItemsList[0].extractedTagAttributes){
        if( id.contains("cover") ){
           //Get media type for the cover items
            string coverMediaType = opfItemsList[1].extractedTagAttributes.get(count);
            //get cover location if media type matches "image"
            if(coverMediaType.contains("image")){
                bookCoverLocation = opfItemsList[2].extractedTagAttributes.get(count);
                bookCoverLocation = aBook.getBaseLocationOfContents() + bookCoverLocation;
                break;
            }
        }
        count++;
    }
    
    //check if cover was not found and assign flag for default cover to be used
    if( bookCoverLocation.length < 1 &&
        "true" == BookwormApp.Utils.fileOperations ("EXISTS", "", bookCoverLocation, "") )
    {
        aBook.setIsBookCoverImagePresent(false);
        debug("Cover image not found for book located at:"+aBook.getBookExtractionLocation());
    } else{
        //copy cover image to bookworm cover image cache
        aBook = BookwormApp.Utils.setBookCoverImage(aBook, bookCoverLocation);
    }
    return aBook;
  }

  public static BookwormApp.Book setBookMetaData(owned BookwormApp.Book aBook, string locationOfOPFFile){
    debug("Initiated process for finding meta data of eBook located at:"+aBook.getBookExtractionLocation());
    //Parse OPF xml file to read the book meta data
    ArrayList<XMLData> inputDataList = new ArrayList<XMLData>();
    inputDataList.add(new XMLData() {
                                        containerTagName = "",
                                        inputTagName = "title",
                                        inputAttributeName = ""}
                                    );
    inputDataList.add(new XMLData() {
                                        containerTagName = "",
                                        inputTagName = "creator",
                                        inputAttributeName = ""}
                                    );
    
    XmlParser thisParser = new XmlParser();
    ArrayList<XMLData> opfItemsList = new ArrayList<XMLData>();
    opfItemsList = thisParser.extractDataFromXML(locationOfOPFFile, inputDataList);
    
    if(opfItemsList[0].extractedTagValues.size > 0){
        string bookTitle = opfItemsList[0].extractedTagValues.get(0);
        if(bookTitle.length > 0){
            aBook.setBookTitle(BookwormApp.Utils.decodeHTMLChars(bookTitle));
            debug("Determined eBook Title as:"+bookTitle);
        }else{
            //If the book title has not been determined, use the file name as book title
            if(aBook.getBookTitle() != null && aBook.getBookTitle().length < 1){
                bookTitle = File.new_for_path(aBook.getBookExtractionLocation()).get_basename();
                if( bookTitle.last_index_of(".") != -1){
                    bookTitle = bookTitle.slice(0, bookTitle.last_index_of("."));
                }
                aBook.setBookTitle(bookTitle);
                debug("File name set as Title:"+bookTitle);
            }
        }
    }

    //determine the author of the book
    if(opfItemsList[1].extractedTagValues.size > 0){
        string bookAuthor = opfItemsList[1].extractedTagValues.get(0);
        if(bookAuthor.length > 0){
            aBook.setBookAuthor(BookwormApp.Utils.decodeHTMLChars(bookAuthor));
            debug("Determined eBook Author as:"+bookAuthor);
        }else{
            //If the book author has not been determined, use a default text for author
            aBook.setBookAuthor(BookwormApp.Constants.TEXT_FOR_UNKNOWN_TITLE);
            debug("Could not determine eBook Author, default Author set");
        }
    }
    return aBook;
  }
}
