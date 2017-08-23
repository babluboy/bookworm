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


  public static string adjustPageContent (owned string pageContentStr){
    settings = BookwormApp.Settings.get_instance();
    string cssForTextAndBackgroundColor = "";
    StringBuilder pageContent = new StringBuilder(pageContentStr);
    BookwormApp.Bookworm.onLoadJavaScript.assign("onload=\"");
    //Set background and font colour based on profile
    string[] profileColorList = settings.list_of_profile_colors.split (",");
    if(BookwormApp.Constants.BOOKWORM_READING_MODE[2] == BookwormApp.Bookworm.settings.reading_profile){
      cssForTextAndBackgroundColor = "
                                        background-color: "+ profileColorList[5] +" !important;
                                        color: "+ profileColorList[4] +" !important;
                                     ";
    }else if(BookwormApp.Constants.BOOKWORM_READING_MODE[1] == BookwormApp.Bookworm.settings.reading_profile){
      cssForTextAndBackgroundColor = "
                                        background-color: "+ profileColorList[3] +" !important;
                                        color: "+ profileColorList[2] +" !important;
                                     ";
    }else{
      cssForTextAndBackgroundColor = "
                                        background-color: "+ profileColorList[1] +" !important;
                                        color: "+ profileColorList[0] +" !important;
                                     ";
    }
    //Set up CSS for book as per preference settings - this will override any css in the book contents
    string cssOverride = BookwormApp.Bookworm.CSSTemplate.replace("$READING_LINE_HEIGHT", BookwormApp.Bookworm.settings.reading_line_height)
                                                         .replace("$READING_WIDTH", (100 - (BookwormApp.Bookworm.settings.reading_width).to_int()).to_string())
                                                         .replace("$FONT_FAMILY", BookwormApp.Bookworm.settings.reading_font_name_family)
                                                         .replace("$FONT_SIZE", BookwormApp.Bookworm.settings.reading_font_size.to_string())
                                                         .replace("$TEXT_AND_BACKGROUND_COLOR", cssForTextAndBackgroundColor);
    //Scroll to the previous vertical position - this should be used:
    //(1)when the book is re-opened from the library and
    //(2) when a book existing in the library is opened from File Explorer using Bookworm
    //The flag for applying the javascript is set from the above two locations
    if(BookwormApp.Bookworm.isPageScrollRequired){
      BookwormApp.Bookworm.onLoadJavaScript.append(" window.scrollTo(0,"+(BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead)).getBookScrollPos().to_string()+");");
      BookwormApp.Bookworm.isPageScrollRequired = false; // stop this function being called subsequently
    }
    //If two page view id required - add a script to set the CSS for two-page if there are more than 500 chars
    if(BookwormApp.Bookworm.settings.is_two_page_enabled){
      BookwormApp.Bookworm.onLoadJavaScript.append(" setTwoPageView();");
    }
    //complete the onload javascript string
    BookwormApp.Bookworm.onLoadJavaScript.append("\"");

    //add onload javascript and css to body tag
    if(pageContent.str.index_of("<BODY") != -1){
      pageContent.assign(pageContent.str.replace("<BODY", BookwormApp.Bookworm.jsFunctions + cssOverride + "<BODY " + BookwormApp.Bookworm.onLoadJavaScript.str));
    }else if (pageContent.str.index_of("<body") != -1){
      pageContent.assign(pageContent.str.replace("<body", BookwormApp.Bookworm.jsFunctions + cssOverride + "<body " + BookwormApp.Bookworm.onLoadJavaScript.str));
    }else{
      pageContent.assign(BookwormApp.Bookworm.jsFunctions + cssOverride + "<BODY " + BookwormApp.Bookworm.onLoadJavaScript.str + ">" + pageContent.str + "</BODY>");
    }
    return pageContent.str;
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
    int searchResultCount = 1;
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
          searchResultsMap.set(searchResultCount.to_string()+"~~"+pageOfResult.str, BookwormApp.Utils.removeTagsFromText(contentOfResult.str));
        }
      }
      searchResultCount++;
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

  public static int getScrollPos(){
    //This function is responsible for returning the vertical scroll position of the webview
    //This should be called when the user leaves reading a book :
    //(1) Header Bar Return to Library and (2) Close Bookworm while in reading mode
		int scrollPos = -1;
		var loop = new MainLoop();
		BookwormApp.AppWindow.aWebView.run_javascript.begin("document.title = window.scrollY;", null, (obj, res) => {
			try{
				BookwormApp.AppWindow.aWebView.run_javascript.end(res);
			}
			catch(GLib.Error e){
				warning("Could not get scroll-pos, javascript error: " + e.message);
			}
			scrollPos = int.parse(BookwormApp.AppWindow.aWebView.get_title());
			loop.quit();
		});
		loop.run();
    debug("Scroll position determined as:"+scrollPos.to_string());
		return scrollPos;
  }

  public static void performStartUpActions(){
    //open the book added, if only one book path is present on command line
    //if this book was not in the library, then the library view will be shown
    if(BookwormApp.Bookworm.pathsOfBooksToBeAdded.length == 2 &&
      "bookworm" == BookwormApp.Bookworm.pathsOfBooksToBeAdded[0])
    {
      BookwormApp.Book requestedBook = null;
      //Check if the requested book is available in the library
      if(BookwormApp.Bookworm.pathsOfBooksInLibraryOnLoadStr.str.index_of(BookwormApp.Bookworm.commandLineArgs[1].strip()) != -1){
        //pick the book from the Initial ArrayList used for holding the books in the library
        //as the BookwormApp.Bookworm.libraryViewMap would not have finished loading
        foreach (BookwormApp.Book aBook in BookwormApp.Library.listOfBooksInLibraryOnLoad) {
          if(BookwormApp.Bookworm.commandLineArgs[1].strip() == aBook.getBookLocation()){
            requestedBook = aBook;
            break;
          }
        }
      }else{
        //pick the book from the BookwormApp.Bookworm.libraryViewMap as it would have been added
        //as part of the code above to create a new book
        requestedBook = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.commandLineArgs[1].strip());
      }
      debug("Bookworm opened for single book["+requestedBook.getBookLocation()+"] - proceed to reading view...");
      if(requestedBook != null){
        //set the name of the book being currently read
        BookwormApp.Bookworm.locationOfEBookCurrentlyRead = BookwormApp.Bookworm.commandLineArgs[1].strip();
        //Initiate Reading the book
        BookwormApp.Bookworm.readSelectedBook(requestedBook);
      }
    }else{
      //check and continue the last book being read - if "Always show library on start is false"
      if((!BookwormApp.Bookworm.settings.is_show_library_on_start) && (BookwormApp.Bookworm.settings.book_being_read != "")){
        //check if the library contains the book being read last
        if(BookwormApp.Bookworm.pathsOfBooksInLibraryOnLoadStr.str.index_of(BookwormApp.Bookworm.settings.book_being_read) != -1){
          //Initiate Reading the book
          BookwormApp.Book lastReadBook = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.settings.book_being_read);
          if(lastReadBook != null){
            //set the name of the book being currently read
            BookwormApp.Bookworm.locationOfEBookCurrentlyRead = BookwormApp.Bookworm.settings.book_being_read;
            //Initiate Reading the book
            BookwormApp.Bookworm.readSelectedBook(lastReadBook);
          }
        }
      }
    }
  }
}
