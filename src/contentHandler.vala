/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and is used for handling the eBook contents
* The prerequisite for the content handler is for the eBook contents to have
* been parsed into HTML format
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
public class BookwormApp.contentHandler {
  public static BookwormApp.Settings settings;

  public static string adjustPageContent (owned string pageContent){
    settings = BookwormApp.Settings.get_instance();
    string javaScriptInjectionPrefix = "onload=\"javascript:";
    string javaScriptInjectionSuffix = "\"";
    StringBuilder onloadJavaScript = new StringBuilder("");
    //Set background and font colour based on profile
    string[] profileColorList = settings.list_of_profile_colors.split (",");
    if(BookwormApp.Constants.BOOKWORM_READING_MODE[2] == BookwormApp.Bookworm.settings.reading_profile){
      onloadJavaScript.append("document.getElementsByTagName('body')[0].style.backgroundColor='"+profileColorList[5]+"';
                               document.getElementsByTagName('BODY')[0].style.color='"+profileColorList[4]+"';
                              ");
    }else if(BookwormApp.Constants.BOOKWORM_READING_MODE[1] == BookwormApp.Bookworm.settings.reading_profile){
      onloadJavaScript.append("document.getElementsByTagName('body')[0].style.backgroundColor='"+profileColorList[3]+"';
                               document.getElementsByTagName('BODY')[0].style.color='"+profileColorList[2]+"';
                              ");
    }else{
      onloadJavaScript.append("document.getElementsByTagName('body')[0].style.backgroundColor='"+profileColorList[1]+"';
                               document.getElementsByTagName('BODY')[0].style.color='"+profileColorList[0]+"';
                              ");
    }
    //Adjust page margin
    string cssOverride = "<style>
                                *{
                                  line-height: "+BookwormApp.Bookworm.settings.reading_line_height+"%;
                                  margin-right: "+BookwormApp.Bookworm.settings.reading_width+"%;
                                  margin-left: "+BookwormApp.Bookworm.settings.reading_width+"%;
                                  font-family: "+BookwormApp.Bookworm.settings.reading_font_name_family+" !important;
                                  font-size: "+BookwormApp.Bookworm.settings.reading_font_size.to_string()+"px !important;
                                }
                          </style>";

    //add onload javascript to body tag
    if(pageContent.index_of("<BODY") != -1){
      pageContent = pageContent.replace("<BODY", cssOverride + "<BODY "+ javaScriptInjectionPrefix + onloadJavaScript.str + javaScriptInjectionSuffix);
    }else if (pageContent.index_of("<body") != -1){
      pageContent = pageContent.replace("<body", cssOverride + "<body "+ javaScriptInjectionPrefix + onloadJavaScript.str + javaScriptInjectionSuffix);
    }else{
      pageContent = cssOverride + "<BODY "+ javaScriptInjectionPrefix + onloadJavaScript.str + javaScriptInjectionSuffix + ">" + pageContent + "</BODY>";
    }
    return pageContent;
  }

  public static string provideContent (owned BookwormApp.Book aBook, int contentLocation){
    debug("Attempting to fetch content at index["+contentLocation.to_string()+"] from book at location:"+aBook.getBaseLocationOfContents());
    StringBuilder contents = new StringBuilder();
    if(contentLocation > -1 && aBook.getBookContentList() != null && aBook.getBookContentList().size > contentLocation){
      string baseLocationOfContents = aBook.getBaseLocationOfContents();
      //handle the case when the content list has html escape chars for the URI
      string bookLocationToRead = BookwormApp.Utils.decodeHTMLChars(aBook.getBookContentList().get(contentLocation));
      //fetch content from extracted book
      contents.assign(BookwormApp.Utils.fileOperations("READ_FILE", bookLocationToRead, "", ""));
      //find list of relative urls with src, href, etc and convert them to absolute ones
      foreach(string tagname in BookwormApp.Constants.TAG_NAME_WITH_PATHS){
      string[] srcList = BookwormApp.Utils.multiExtractBetweenTwoStrings(contents.str, tagname, "\"");
        StringBuilder srcItemFullPath = new StringBuilder();
        foreach(string srcItem in srcList){
          srcItemFullPath.assign(BookwormApp.Utils.getFullPathFromFilename(aBook.getBookExtractionLocation(), srcItem));
          contents.assign(contents.str.replace(tagname+srcItem+"\"",BookwormApp.Utils.encodeHTMLChars(tagname+srcItemFullPath.str)+"\""));
        }
      }
      //update the content for required manipulation
      contents.assign(adjustPageContent(contents.str));
    }else{
      //requested content not available
      aBook.setParsingIssue(BookwormApp.Constants.TEXT_FOR_CONTENT_NOT_FOUND_ISSUE);
      BookwormApp.AppWindow.showInfoBar(aBook, Gtk.MessageType.WARNING);
    }
    debug("Completed fetching content from book at location:"+aBook.getBaseLocationOfContents() + "for page:" + contentLocation.to_string());
    return contents.str;
  }

  public static HashMap<string,string> searchBookContents(BookwormApp.Book aBook, string searchString){
    HashMap<string,string> searchResultsMap = new HashMap<string,string>();
    string bookSearchResults = BookwormApp.Utils.execute_sync_command("grep -i -r -o -P -w '.{0,50}"+BookwormApp.AppHeaderBar.headerSearchBar.get_text()+".{0,50}' \""+aBook.getBookExtractionLocation()+"\"");
    string[] individualLines = bookSearchResults.strip().split ("\n",-1);
    StringBuilder pageOfResult = new StringBuilder("");
    StringBuilder contentOfResult = new StringBuilder("");
    foreach (string aSearchResult in individualLines) {
      if(aSearchResult.index_of(":") != -1 && aSearchResult.index_of(":") > 0 && aSearchResult.index_of(":") < aSearchResult.length){
        pageOfResult.assign(aSearchResult.slice(0, aSearchResult.index_of(":")));
        if(!(aBook.getBookContentList().contains(pageOfResult.str))){
          //handle the case when the spine data has HTML Escape characters
          foreach (string contentListURI in aBook.getBookContentList()) {
            if(BookwormApp.Utils.decodeHTMLChars(contentListURI) == pageOfResult.str){
              pageOfResult.assign(contentListURI);
              break;
            }
          }
          //If the location still could not be matched, then assign a blank location
          if(!(aBook.getBookContentList().contains(pageOfResult.str))){
            pageOfResult.assign("");
          }
        }

        contentOfResult.assign(aSearchResult.slice(aSearchResult.index_of(":")+1, aSearchResult.length));
        //ignore the results from ncx,opf file
        if(pageOfResult.str.index_of("ncx") == -1 && pageOfResult.str.index_of("opf") == -1 && pageOfResult.str.length > 1){
          searchResultsMap.set(pageOfResult.str, BookwormApp.Utils.removeTagsFromText(contentOfResult.str));
        }
      }
    }
    return searchResultsMap;
  }

  public static void refreshCurrentPage(){
    if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[1]){
      BookwormApp.Book currentBookForRefresh = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
      currentBookForRefresh = BookwormApp.Bookworm.renderPage(BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead), "");
      BookwormApp.Bookworm.libraryViewMap.set(BookwormApp.Bookworm.locationOfEBookCurrentlyRead, currentBookForRefresh);
    }
  }
}
