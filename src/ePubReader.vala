/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm.
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

public class BookwormApp.ePubReader {

  public static string extractEBook(string eBookLocation){
    string extractionLocation = "";
    debug("Initiated process for content extraction of eBook located at:"+eBookLocation);
    //create temp location for extraction of eBook
    extractionLocation = BookwormApp.Constants.EPUB_EXTRACTION_LOCATION + File.new_for_path(eBookLocation).get_basename();
    //check and create directory for extracting contents of ebook
    BookwormApp.Utils.fileOperations("CREATEDIR", extractionLocation, "", "");
    //unzip eBook contents into temp location
    BookwormApp.Utils.execute_sync_command("unzip -o \"" + eBookLocation + "\" -d \""+ extractionLocation +"\"");
    debug("eBook contents extracted sucessfully into location:"+extractionLocation);
    return extractionLocation;
  }

  public static string getLocationOfContentOPFFile(string extractionLocation){
    //ensure correct mime type in mimetype file
    string ePubMimeContents = BookwormApp.Utils.fileOperations("READ", extractionLocation, BookwormApp.Constants.EPUB_MIME_SPECIFICATION_FILENAME, "");
    debug("Mime Contents in file :"+extractionLocation+"/"+BookwormApp.Constants.EPUB_MIME_SPECIFICATION_FILENAME+" is:"+ ePubMimeContents);
    if(ePubMimeContents.strip() != BookwormApp.Constants.EPUB_MIME_SPECIFICATION_CONTENT){
        debug("Mime Contents in file :"+extractionLocation+"/"+BookwormApp.Constants.EPUB_MIME_SPECIFICATION_FILENAME+" is not :"+ BookwormApp.Constants.EPUB_MIME_SPECIFICATION_CONTENT);
        return "false";
    }
    //read the META-INF/container.xml file
    string metaInfContents = BookwormApp.Utils.fileOperations("READ", extractionLocation, BookwormApp.Constants.EPUB_META_INF_FILENAME, "");
    debug("META-INF Contents in file :"+ extractionLocation+"/"+BookwormApp.Constants.EPUB_META_INF_FILENAME+" is:"+ metaInfContents);
    //locate the path to the contents
    int startPosOfContentOPFFile = metaInfContents.index_of("<rootfile full-path=\"")+("<rootfile full-path=\"").length;
    int endPosOfContentOPFFile = metaInfContents.index_of("\"", startPosOfContentOPFFile+1);
    string ContentOPFFilePath = metaInfContents.slice(startPosOfContentOPFFile,endPosOfContentOPFFile);
    debug("CONTENT.OPF file relative path [Fetched from file:"+ extractionLocation+"/"+BookwormApp.Constants.EPUB_META_INF_FILENAME+"] is:"+ ContentOPFFilePath);
    string locationOfOPFFile = extractionLocation + "/" + ContentOPFFilePath;
    debug ("Absolute path to CONTENT.OPF : "+locationOfOPFFile);
    return locationOfOPFFile;
  }

  public static BookwormApp.Book getBookCoverImageLocation (owned BookwormApp.Book aBook, string bookworm_config_path){
    debug("Initiated process for cover image extraction of eBook located at:"+aBook.getBookExtractionLocation());
    string bookCoverLocation = "";
    string extractionLocation = aBook.getBookExtractionLocation();
    string locationOfOPFFile = getLocationOfContentOPFFile(extractionLocation);
    string baseLocationOfContents = locationOfOPFFile.replace(File.new_for_path(locationOfOPFFile).get_basename(), "");
    //read contents from content.opf file
    string OpfContents = BookwormApp.Utils.fileOperations("READ_FILE", locationOfOPFFile, "", "");
    //read contents from spine and manifest and populate reading ArrayList
    string manifestData = BookwormApp.Utils.extractXMLTag(OpfContents, "<manifest", "</manifest>");
    string[] manifestItemList = BookwormApp.Utils.multiExtractBetweenTwoStrings (manifestData, "<item", "/>");
    //determine the location of the book's cover image
    for (int i = 0; i < manifestItemList.length; i++) {
        if (manifestItemList[i].down().contains("media-type=\"image") && manifestItemList[i].down().contains("cover")) {
            int startIndexOfCoverLocation = manifestItemList[i].index_of("href=\"")+6;
            int endIndexOfCoverLocation = manifestItemList[i].index_of("\"", startIndexOfCoverLocation+1);
            if(startIndexOfCoverLocation != -1 && endIndexOfCoverLocation != -1 && endIndexOfCoverLocation > startIndexOfCoverLocation){
              bookCoverLocation = baseLocationOfContents + manifestItemList[i].slice(startIndexOfCoverLocation, endIndexOfCoverLocation);
            }
            break;
        }
    }
    //check if cover was not found and assign flag
    if(bookCoverLocation == null || bookCoverLocation.length < 1){
      aBook.setIsBookCoverImagePresent(false);
      //aBook.setBookCoverLocation(BookwormApp.Constants.DEFAULT_COVER_IMAGE_LOCATION);
      debug("eBook cover image not found");
    }else{
      //cover was extracted from the ebook contents
      aBook.setIsBookCoverImagePresent(true);
      //copy cover image to bookworm cover image location
      File coverImageFile = File.new_for_commandline_arg(bookCoverLocation);
      string bookwormCoverLocation = bookworm_config_path+"/covers/"+aBook.getBookLocation().replace("/", "_").replace(" ", "")+"_"+coverImageFile.get_basename();
      BookwormApp.Utils.execute_sync_command("cp \""+bookCoverLocation+"\" \""+bookwormCoverLocation+"\"");
      aBook.setBookCoverLocation(bookwormCoverLocation);
      debug("eBook cover image extracted sucessfully into location:"+bookwormCoverLocation);
    }
    return aBook;
  }

  public static BookwormApp.Book getBookTitle(owned BookwormApp.Book aBook, string bookworm_config_path){
    debug("Initiated process for finding title of eBook located at:"+aBook.getBookExtractionLocation());
    string extractionLocation = aBook.getBookExtractionLocation();
    string locationOfOPFFile = getLocationOfContentOPFFile(extractionLocation);
    string baseLocationOfContents = locationOfOPFFile.replace(File.new_for_path(locationOfOPFFile).get_basename(), "");
    //read contents from OPF file
    string OpfContents = BookwormApp.Utils.fileOperations("READ_FILE", locationOfOPFFile, "", "");
    //determine the title of the book
    if(OpfContents.contains("<dc:title") && OpfContents.contains("</dc:title>")){
      int startOfTitleText = OpfContents.index_of(">", OpfContents.index_of("<dc:title"));
      int endOfTittleText = OpfContents.index_of("</dc:title>", startOfTitleText);
      debug("startOfTitleText="+startOfTitleText.to_string()+", endOfTittleText="+endOfTittleText.to_string());
      if(startOfTitleText != -1 && endOfTittleText != -1 && endOfTittleText > startOfTitleText){
        string bookTitle = OpfContents.slice(startOfTitleText+1, endOfTittleText);
        aBook.setBookTitle(bookTitle);
        debug("Determined eBook Title as:"+bookTitle);
      }else{
        aBook.setBookTitle(BookwormApp.Constants.TEXT_FOR_UNKNOWN_TITEL);
        debug("Could not determine eBook Title, default title set");
      }
    }else{
      aBook.setBookTitle(BookwormApp.Constants.TEXT_FOR_UNKNOWN_TITEL);
      debug("Could not determine eBook Title, default title set");
    }
    return aBook;
  }

  public static BookwormApp.Book getListOfPagesInBook(owned BookwormApp.Book aBook){
    string extractionLocation = aBook.getBookExtractionLocation();
    string locationOfOPFFile = getLocationOfContentOPFFile(extractionLocation);
    string baseLocationOfContents = locationOfOPFFile.replace(File.new_for_path(locationOfOPFFile).get_basename(), "");
    aBook.setBaseLocationOfContents(baseLocationOfContents);
    //read contents from content.opf file
    string OpfContents = BookwormApp.Utils.fileOperations("READ_FILE", locationOfOPFFile, "", "");
    //parse eBook and read contents of spine and manifest
    string spineData = BookwormApp.Utils.extractXMLTag(OpfContents, "<spine", "</spine>");
    string manifestData = BookwormApp.Utils.extractXMLTag(OpfContents, "<manifest", "</manifest>");
    string[] manifestItemList = BookwormApp.Utils.multiExtractBetweenTwoStrings (manifestData, "<item", "/>");

    int positionOfSpineItemref = 0;
    int positionOfManifestItemref = 0;
    int positionOfManifestDataStart = 0;
    int positionOfManifestDataEnd = 0;
    StringBuilder bufferForSpineDataExtraction = new StringBuilder("");
    StringBuilder bufferForManifestDataExtraction = new StringBuilder("");
    StringBuilder bufferForLocationOfContentData = new StringBuilder("");
    //loop through all itemref elements in spine and determine respective locations
    while (positionOfSpineItemref != -1){
      bufferForSpineDataExtraction.erase(0, -1);
      if(positionOfSpineItemref > 0){ //condition to ignore the first position
        int positionOfIdrefStart = spineData.index_of ("idref=", positionOfSpineItemref+1) + 7;
        int positionOfIdrefEnd = spineData.index_of("\"", positionOfIdrefStart+1);
        debug("spine data="+spineData.slice(positionOfIdrefStart, positionOfIdrefEnd));
        if(positionOfIdrefStart != -1 && positionOfIdrefEnd != -1 && positionOfIdrefEnd > positionOfIdrefStart){
          bufferForSpineDataExtraction.append(spineData.slice(positionOfIdrefStart, positionOfIdrefEnd));
          //find the item in manifest matching the spine itemref after looping through all item ids in the manifest
          while (positionOfManifestItemref != -1){
            bufferForManifestDataExtraction.erase(0, -1);
            bufferForManifestDataExtraction.append(manifestData.slice(manifestData.index_of("<item", positionOfManifestItemref), manifestData.index_of("/>", positionOfManifestItemref)));
            //match spine idref to manifest item id
            if(bufferForManifestDataExtraction.str.contains("id=\""+bufferForSpineDataExtraction.str+"\"")){
              //add manifest location item to array list in order of reading
              positionOfManifestDataStart = bufferForManifestDataExtraction.str.index_of("href=\"")+6;
              positionOfManifestDataEnd = bufferForManifestDataExtraction.str.index_of("\"", bufferForManifestDataExtraction.str.index_of("href=\"")+8);
              bufferForLocationOfContentData.erase(0, -1);
              bufferForLocationOfContentData.append(aBook.getBaseLocationOfContents())
                                            .append(bufferForManifestDataExtraction.str.slice(positionOfManifestDataStart, positionOfManifestDataEnd));
              aBook.setBookContentList(bufferForLocationOfContentData.str);
              debug("Matching spine reference["+bufferForSpineDataExtraction.str+"], extracted content location:"+bufferForLocationOfContentData.str);
              break;
            }
            positionOfManifestItemref = manifestData.index_of ("<item", positionOfManifestItemref+5);
          }
          positionOfManifestItemref = 0;
        }
      }
      positionOfSpineItemref = spineData.index_of ("<itemref", positionOfSpineItemref+1);
    }
    debug("Completed extracting location of content files in ebook. Number of content files = "+aBook.getBookContentList().size.to_string());
    return aBook;
  }

  public static BookwormApp.Book renderPage (WebKit.WebView aWebView, owned BookwormApp.Book aBook, string direction){
    debug("Starting to renderPage for direction["+direction+"] on book located at "+aBook.getBookLocation());
    StringBuilder contents = new StringBuilder();
    string baseLocationOfContents = aBook.getBaseLocationOfContents();
    int currentContentLocation = 0;
    switch(direction){
      case "TABLE_OF_CONTENTS": // Generate the table of contents
        //render the table of content
        if(aBook.getTOCHTMLContent() == null || aBook.getTOCHTMLContent().length < 1 ){
          if(aBook.getBookContentList() != null && aBook.getBookContentList().size > 0){
            aBook.setTOCHTMLContent(BookwormApp.Utils.createTableOfContents(aBook.getBookContentList()));
          }else{
            getListOfPagesInBook(aBook);
            aBook.setTOCHTMLContent(BookwormApp.Utils.createTableOfContents(aBook.getBookContentList()));
          }
        }
        aWebView.load_html(aBook.getTOCHTMLContent(), BookwormApp.Constants.PREFIX_FOR_FILE_URL);
        break;
      default: // this case is for moving forward or backward
        //check current content location of book
        if(aBook.getBookPageNumber() != -1){
          currentContentLocation = aBook.getBookPageNumber();
          debug("Book has a CURRENT_LOCATION set at :"+currentContentLocation.to_string());
          if(direction == "FORWARD" && currentContentLocation < (aBook.getBookContentList().size - 1)){
            currentContentLocation++;
            aBook.setBookPageNumber(currentContentLocation);
          }else{
            aBook.setIfPageForward(false);
          }
          if(direction == "BACKWARD" && currentContentLocation > 0){
            currentContentLocation--;
            aBook.setBookPageNumber(currentContentLocation);
          }else{
            aBook.setIfPageBackward(false);
          }
        }else{
          aBook.setBookPageNumber(0);
          currentContentLocation = 0;
          debug("Book did not had a CURRENT_LOCATION set.");
        }
        if(aBook.getBookContentList().size > 0 && aBook.getBookContentList().size >= currentContentLocation){
          debug("Rendering location ["+currentContentLocation.to_string()+"]"+aBook.getBookContentList().get(currentContentLocation));
        }else{
          //No content list extracted from eBook
          warning("No contents determined for the book at location ["+currentContentLocation.to_string()+"], no rendering possible.");
          aWebView.load_html(BookwormApp.Constants.TEXT_FOR_RENDERING_ISSUE, "");
          return aBook;
        }
        contents.assign(BookwormApp.Utils.fileOperations("READ_FILE", aBook.getBookContentList().get(currentContentLocation), "", ""));
        //find list of relative urls with src, href, etc and convert them to absolute ones
        foreach(string tagname in BookwormApp.Constants.TAG_NAME_WITH_PATHS){
        string[] srcList = BookwormApp.Utils.multiExtractBetweenTwoStrings(contents.str, tagname, "\"");
          StringBuilder srcItemBaseName = new StringBuilder();
          StringBuilder srcItemFullPath = new StringBuilder();
          foreach(string srcItem in srcList){
            srcItemBaseName.assign(File.new_for_path(srcItem).get_basename());
            srcItemFullPath.assign(BookwormApp.Utils.getFullPathFromFilename(aBook.getBookExtractionLocation(), srcItemBaseName.str));
            contents.assign(contents.str.replace(tagname+srcItem+"\"",tagname+srcItemFullPath.str+"\""));
          }
        }

        //render the content on webview
        aWebView.load_html(contents.str, BookwormApp.Constants.PREFIX_FOR_FILE_URL);
        break;
    }
    return aBook;
  }
}
