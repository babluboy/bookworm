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

public class BookwormApp.ePubReader{

  public static string baseLocationOfContents = "";
  public static int currentPageNumber = -1;
  public static Gee.ArrayList<string> readingListData = new Gee.ArrayList<string>();
  public static string bookTitle = "";
  public static string bookCoverLocation = "";
  public static string eBookLocation = "";

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

  public static Gee.HashMap<string,string> getBookCoverImageLocation (owned Gee.HashMap<string,string> bookDetailsMap){
    string bookCoverLocation = "";
    string extractionLocation = bookDetailsMap.get("LOCATION_OF_EXTRACTED_EBOOK_CONTENTS");
    string locationOfOPFFile = getLocationOfContentOPFFile(extractionLocation);
    bookDetailsMap.set("LOCATION_OF_EBOOK_CONTENT_OPF_FILE", locationOfOPFFile);
    string baseLocationOfContents = locationOfOPFFile.replace(File.new_for_path(locationOfOPFFile).get_basename(), "");
    bookDetailsMap.set("BASE_LOCATION_OF_EBOOK_CONTENTS", baseLocationOfContents);
    //read contents from content.opf file
    string OpfContents = BookwormApp.Utils.fileOperations("READ_FILE", locationOfOPFFile, "", "");
    //determine the title of the book
    if(OpfContents.contains("<dc:title>") && OpfContents.contains("</dc:title>")){
      string bookTitle = OpfContents.slice(OpfContents.index_of("<dc:title>")+"<dc:title>".length, OpfContents.index_of("</dc:title>"));
      bookDetailsMap.set("EBOOK_TITLE", bookTitle);
      debug("Determined eBook Title as:"+bookTitle);
    }
    //read contents from spine and manifest and populate reading ArrayList
    string spineData = BookwormApp.Utils.extractXMLTag(OpfContents, "<spine", "</spine>");
    //debug("Spine Data:"+spineData);
    string manifestData = BookwormApp.Utils.extractXMLTag(OpfContents, "<manifest", "</manifest>");
    string[] manifestItemList = BookwormApp.Utils.multiExtractBetweenTwoStrings (manifestData, "<item", "/>");
    //debug("Manifest Data:"+manifestData);
    //determine the location of the book's cover image
    for (int i = 0; i < manifestItemList.length; i++) {
        debug("Manifest data contaning cover image:"+manifestItemList[i]);
        if (manifestItemList[i].down().contains("media-type=\"image") && manifestItemList[i].down().contains("cover")) {
            int startIndexOfCoverLocation = manifestItemList[i].index_of("href=\"")+6;
            int endIndexOfCoverLocation = manifestItemList[i].index_of("\"", startIndexOfCoverLocation+1);
            if(startIndexOfCoverLocation != -1 && endIndexOfCoverLocation != -1 && endIndexOfCoverLocation > startIndexOfCoverLocation){
              bookCoverLocation = baseLocationOfContents + manifestItemList[i].slice(startIndexOfCoverLocation, endIndexOfCoverLocation);
              bookDetailsMap.set("LOCATION_OF_EBOOK_COVER_PAGE_IMAGE", bookCoverLocation);
              debug("Book Cover image located at:"+bookCoverLocation);
            }
            break;
        }
    }
    return bookDetailsMap;
  }

  public static Gee.ArrayList<string> getListOfPagesInBook(owned Gee.HashMap<string,string> bookDetailsMap){
    Gee.ArrayList<string> pageContentList = new Gee.ArrayList<string>();
    //read contents from content.opf file
    string OpfContents = BookwormApp.Utils.fileOperations("READ_FILE", bookDetailsMap.get("LOCATION_OF_EBOOK_CONTENT_OPF_FILE"), "", "");
    //parse eBook and read contents of spine and manifest
    string spineData = BookwormApp.Utils.extractXMLTag(OpfContents, "<spine", "</spine>");
    //debug("Spine Data:"+spineData);
    string manifestData = BookwormApp.Utils.extractXMLTag(OpfContents, "<manifest", "</manifest>");
    string[] manifestItemList = BookwormApp.Utils.multiExtractBetweenTwoStrings (manifestData, "<item", "/>");
    //debug("Manifest Data:"+manifestData);
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
        bufferForSpineDataExtraction.append(spineData.slice(positionOfSpineItemref+16, spineData.index_of("\"", positionOfSpineItemref+17)));
        //debug("Extracted Spine idref:"+bufferForSpineDataExtraction.str);
        //find the item in manifest matching the spine itemref after looping through all item ids in the manifest
        while (positionOfManifestItemref != -1){
          bufferForManifestDataExtraction.erase(0, -1);
          bufferForManifestDataExtraction.append(manifestData.slice(manifestData.index_of("<item", positionOfManifestItemref), manifestData.index_of("\"/>", positionOfManifestItemref)));
          //match spine idref to manifest item id
          if(bufferForManifestDataExtraction.str.contains("id=\""+bufferForSpineDataExtraction.str+"\"")){
            //add manifest location item to array list in order of reading
            positionOfManifestDataStart = bufferForManifestDataExtraction.str.index_of("href=\"")+6;
            positionOfManifestDataEnd = bufferForManifestDataExtraction.str.index_of("\"", bufferForManifestDataExtraction.str.index_of("href=\"")+8);
            bufferForLocationOfContentData.erase(0, -1);
            bufferForLocationOfContentData.append(bookDetailsMap.get("BASE_LOCATION_OF_EBOOK_CONTENTS"))
                                          .append(bufferForManifestDataExtraction.str.slice(positionOfManifestDataStart, positionOfManifestDataEnd));
            debug("Extracted content location:"+bufferForLocationOfContentData.str);
            pageContentList.add (bufferForLocationOfContentData.str);
            break;
          }
          positionOfManifestItemref = manifestData.index_of ("<item", positionOfManifestItemref+5);
        }
        positionOfManifestItemref = 0;
      }
      positionOfSpineItemref = spineData.index_of ("<itemref idref=", positionOfSpineItemref+1);
    }(
    debug("Completed extracting location of content files in ebook. Number of content files = "+pageContentList.size.to_string()));
    return pageContentList;
  }

  public static Gee.HashMap<string,string> renderPage (WebKit.WebView aWebView, owned Gee.HashMap<string,string> bookDetailsMap, Gee.ArrayList<string> pageContentList, string direction){
    string baseLocationOfContents = bookDetailsMap.get("BASE_LOCATION_OF_EBOOK_CONTENTS");
    int currentContentLocation = 0;
    //check current content location of book
    if(bookDetailsMap.has_key("CURRENT_LOCATION_OF_EBOOK_CONTENTS")){
      currentContentLocation = int.parse(bookDetailsMap.get("CURRENT_LOCATION_OF_EBOOK_CONTENTS"));
      debug("Book has a CURRENT_LOCATION set at :"+currentContentLocation.to_string());
      if(direction == "FORWARD" && currentContentLocation < (pageContentList.size - 1)){
        currentContentLocation++;
        bookDetailsMap.set("CURRENT_LOCATION_OF_EBOOK_CONTENTS", currentContentLocation.to_string());
      }else{
        bookDetailsMap.set("IS_FORWARD_POSSIBLE", "false");
      }
      if(direction == "BACKWARD" && currentContentLocation > 0){
        currentContentLocation--;
        bookDetailsMap.set("CURRENT_LOCATION_OF_EBOOK_CONTENTS", currentContentLocation.to_string());
      }else{
        bookDetailsMap.set("IS_BACKWARD_POSSIBLE", "false");
      }
    }else{
      bookDetailsMap.set("CURRENT_LOCATION_OF_EBOOK_CONTENTS", "0");
      debug("Book did not had a CURRENT_LOCATION set.");
    }
    debug("Rendering location ["+currentContentLocation.to_string()+"]"+pageContentList.get(currentContentLocation));
    //extract contents from location and format the same
    string contents = BookwormApp.Utils.fileOperations("READ_FILE", pageContentList.get(currentContentLocation), "", "");
    if(contents.index_of("<img src=\"") != -1){
      contents = contents.replace("<img src=\"","<img src=\""+baseLocationOfContents+"/");
    }else{
      contents = contents.replace("src=\"","src=\""+baseLocationOfContents+"/");
    }
    contents = contents.replace("xlink:href=\"","xlink:href=\""+baseLocationOfContents+"/");

    //render the content on webview
    aWebView.load_html(contents, "file:///");

    return bookDetailsMap;
  }
}
