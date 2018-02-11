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

    public static BookwormApp.Book renderPage (owned BookwormApp.Book aBook, owned string direction){
        debug("Starting to render page contents for book ["+aBook.getBookTitle()+"] for direction ["+direction+"]");
        int currentContentLocation = aBook.getBookPageNumber();
        //set page number based on direction of navigation
        switch(direction){
            case "FORWARD"://This is for moving the book forward
                if(aBook.getIfPageForward()){
                    currentContentLocation++;
                    aBook.setBookPageNumber(currentContentLocation);
                }
                break;
            case "BACKWARD"://This is for moving the book backwards
                if(aBook.getIfPageBackward()){
                    currentContentLocation--;
                    aBook.setBookPageNumber(currentContentLocation);
                }
                break;
            case "SEARCH"://Load the page and scroll to the search text
                break;
            default://This is for opening the current page of the book
                //No change of page number required
                break;
        }
        string bookContent = contentHandler.provideContent(aBook,currentContentLocation, direction);
        //render the content on webview
        BookwormApp.AppWindow.aWebView.load_html(bookContent, BookwormApp.Constants.PREFIX_FOR_FILE_URL);
        //set the focus to the webview to capture keypress events
        BookwormApp.AppWindow.aWebView.grab_focus();
        //set the bookmak icon on the header
        handleBookMark("DISPLAY");
        //set the navigation controls
        aBook = BookwormApp.Bookworm.controlNavigation(aBook);
        //set the current value of the page slider
        BookwormApp.AppWindow.pageAdjustment.set_value(currentContentLocation+1);
        return aBook;
    }

    public static string provideContent (owned BookwormApp.Book aBook, int contentLocation, string mode){
        debug("Attempting to fetch content at index["+contentLocation.to_string()+"] from book at location:"+aBook.getBaseLocationOfContents());
        StringBuilder contents = new StringBuilder();
        if(contentLocation > -1 && aBook.getBookContentList() != null && aBook.getBookContentList().size > contentLocation){
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
            contents.assign(adjustPageContent(aBook, contents.str, mode));
        }else{
            //requested content not available
            aBook.setParsingIssue(BookwormApp.Constants.TEXT_FOR_CONTENT_NOT_FOUND_ISSUE);
            BookwormApp.AppWindow.showInfoBar(aBook, Gtk.MessageType.WARNING);
        }
        debug("Completed fetching content from book at location:"+aBook.getBaseLocationOfContents() + "for page:" + contentLocation.to_string());
        return contents.str;
    }

    public static void handleBookMark(string action){
	    //get the book being currently read
		BookwormApp.Book aBook = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
		switch(action){
		    case "DISPLAY":
			    if(aBook != null && aBook.getBookmark() != null && aBook.getBookmark().index_of(aBook.getBookPageNumber().to_string()) != -1){
					//display bookmark as active
					BookwormApp.AppHeaderBar.bookmark_active_button.set_visible(true);
					BookwormApp.AppHeaderBar.bookmark_inactive_button.set_visible(false);
				}else{
					//display bookmark as inactive
					BookwormApp.AppHeaderBar.bookmark_active_button.set_visible(false);
					BookwormApp.AppHeaderBar.bookmark_inactive_button.set_visible(true);
				}
				break;
            case "ACTIVE_CLICKED":
				BookwormApp.AppHeaderBar.bookmark_active_button.set_visible(false);
				BookwormApp.AppHeaderBar.bookmark_inactive_button.set_visible(true);
				//set the bookmark
				aBook.setBookmark(aBook.getBookPageNumber(), action);
				break;
            case "INACTIVE_CLICKED":
				BookwormApp.AppHeaderBar.bookmark_active_button.set_visible(true);
				BookwormApp.AppHeaderBar.bookmark_inactive_button.set_visible(false);
				//set the bookmark
				aBook.setBookmark(aBook.getBookPageNumber(), action);
				break;
			default:
				break;
		}
		//update book details to libraryView Map
		if(aBook != null){
			debug("updating libraryViewMap with bookmark info...");
			BookwormApp.Bookworm.libraryViewMap.set(BookwormApp.Bookworm.locationOfEBookCurrentlyRead, aBook);
		}
    }

    public static string adjustPageContent (BookwormApp.Book aBook, owned string pageContentStr, string mode){
        settings = BookwormApp.Settings.get_instance();
        string cssForTextAndBackgroundColor = "";
        StringBuilder pageContent = new StringBuilder(pageContentStr);
        BookwormApp.Bookworm.onLoadJavaScript.assign("onload=\"");
        string currentBookwormScripts = BookwormApp.Bookworm.bookwormScripts;

        //For the Title Page (first or second page), resize height and width of images
        if(aBook.getBookPageNumber() < 2 && (pageContentStr.contains("image") || pageContentStr.contains("img"))) {
            currentBookwormScripts = currentBookwormScripts.replace("$TITLE_PAGE_IMAGE", "* ");
        }
        //Set background and font colour based on profile
        string[] profileColorList = settings.list_of_profile_colors.split (",");
        
        if(BookwormApp.Constants.BOOKWORM_READING_MODE[4] == BookwormApp.Bookworm.settings.reading_profile){
            //default dark profile
            cssForTextAndBackgroundColor = " background-color: #002b36"+
                                                                          " !important; color: #93a1a1"+
                                                                          " !important;";
            currentBookwormScripts = currentBookwormScripts.replace("$SCROLLBAR_BACKGROUND", "#002b36");
        } else if(BookwormApp.Constants.BOOKWORM_READING_MODE[3] == BookwormApp.Bookworm.settings.reading_profile){
            //default light profile
            cssForTextAndBackgroundColor = " background-color: #fbfbfb"+ 
                                                                          " !important; color: #000000"+
                                                                          " !important;";
            currentBookwormScripts = currentBookwormScripts.replace("$SCROLLBAR_BACKGROUND", "#fbfbfb");
        } else if(BookwormApp.Constants.BOOKWORM_READING_MODE[2] == BookwormApp.Bookworm.settings.reading_profile){
            cssForTextAndBackgroundColor = " background-color: "+ profileColorList[5] +
                                                                          " !important; color: "+ profileColorList[4] +
                                                                          " !important;";
            currentBookwormScripts = currentBookwormScripts.replace("$SCROLLBAR_BACKGROUND", profileColorList[5]);
        } else if(BookwormApp.Constants.BOOKWORM_READING_MODE[1] == BookwormApp.Bookworm.settings.reading_profile){
            cssForTextAndBackgroundColor = " background-color: "+ profileColorList[3] +
                                                                          " !important; color: "+ profileColorList[2] +
                                                                          " !important;";
            currentBookwormScripts = currentBookwormScripts.replace("$SCROLLBAR_BACKGROUND", profileColorList[3]);
        } else{
            cssForTextAndBackgroundColor = " background-color: "+ profileColorList[1] +
                                                                          " !important; color: "+ profileColorList[0] +
                                                                          " !important;";
            currentBookwormScripts = currentBookwormScripts.replace("$SCROLLBAR_BACKGROUND", profileColorList[1]);
        }
        //Set up CSS for book as per preference settings - this will override any css in the book contents
        currentBookwormScripts = currentBookwormScripts
                                     .replace("$READING_LINE_HEIGHT", BookwormApp.Bookworm.settings.reading_line_height)
                                     .replace("$READING_WIDTH", (100 - int.parse(BookwormApp.Bookworm.settings.reading_width)).to_string())
                                     .replace("$FONT_FAMILY", BookwormApp.Bookworm.settings.reading_font_name_family)
                                     .replace("$FONT_SIZE", BookwormApp.Bookworm.settings.reading_font_size.to_string())
                                     .replace("$READING_TEXT_ALIGN", BookwormApp.Bookworm.settings.text_alignment)
                                     .replace("$TEXT_AND_BACKGROUND_COLOR", cssForTextAndBackgroundColor);
        //Scroll to the previous vertical position - this should be used:
        //(1) when the book is re-opened from the library and
        //(2) when a book existing in the library is opened from File Explorer using Bookworm
        //(3) when clicking on a link in the TableOfContents which has an anchor
        //The flag for applying the javascript is set from the above locations
        if(BookwormApp.Bookworm.isPageScrollRequired){
            //check if an Anchor is present and set up the javascript for the same
            if(aBook.getAnchor().length > 0){
                BookwormApp.Bookworm.onLoadJavaScript.append(" document.getElementById('"+aBook.getAnchor()+"').scrollIntoView();");
            }else{ //set up the javascript for scrolling to last read position
                BookwormApp.Bookworm.onLoadJavaScript.append(" window.scrollTo(0,"+
                       (BookwormApp.Bookworm.libraryViewMap.get(
                                                BookwormApp.Bookworm.locationOfEBookCurrentlyRead)
                       ).getBookScrollPos().to_string()+");");
            }
            BookwormApp.Bookworm.isPageScrollRequired = false; // stop this function being called subsequently
        }
        //If two page view id required - add a script to set the CSS for two-page if there are more than 500 chars
        if(BookwormApp.Bookworm.settings.is_two_page_enabled){
            BookwormApp.Bookworm.onLoadJavaScript.append(" setTwoPageView();");
        }
        //Overlay any Annotated text
        foreach (var entry in aBook.getAnnotationList().entries) {
            if(aBook.getBookPageNumber().to_string() == entry.key.split("#~~#")[0]){
                BookwormApp.Bookworm.onLoadJavaScript.append(" overlayAnnotation('"+entry.key.split("#~~#")[1]+"');");
            }
        }

        //Highlight and Scroll To Search String on page if required
        if("SEARCH" == mode){
            if(BookwormApp.Bookworm.bookTextSearchString.length > 1){
                string[] searchTokens = BookwormApp.Bookworm.bookTextSearchString.split("#~~#");
                if(searchTokens.length == 2){
                    //limit the search string to one word on either side of search text
                    int startPosOfSearchString = searchTokens[1].index_of(searchTokens[0]);
                    int endPosOfSearchString = startPosOfSearchString + searchTokens[0].length;
                    int lengthOfLineWithSearchString = searchTokens[1].length;
                    int countSpaces = 0;
                    int startPosOfStringToBeHighlighted = 0;
                    int endPosOfStringToBeHighlighted = 0;
                    string stringToBeHighlighted = "";
                    if(startPosOfSearchString != -1){
                        //get the position of the word before the searched phrase
                        for (int i=startPosOfSearchString; i>1; i--){
                            //match the second space before the search string
                            if(" " == searchTokens[1].slice(i, i+1)){
                                countSpaces++;
                            }
                            if(countSpaces == 2){
                                startPosOfStringToBeHighlighted = i+1;
                                break;
                            }
                        }
                        //get the position of the word after the searched phrase
                        countSpaces = 0;
                        for (int j=endPosOfSearchString; j<lengthOfLineWithSearchString; j++){
                            //match the second space before the search string
                            if(" " == searchTokens[1].slice(j, j+1)){
                                countSpaces++;
                            }
                            if(countSpaces == 2){
                                endPosOfStringToBeHighlighted = j;
                                break;
                            }
                        }
                        //form the string to be highlighted
                        if(endPosOfStringToBeHighlighted > startPosOfStringToBeHighlighted){
                            stringToBeHighlighted = searchTokens[1].slice(startPosOfStringToBeHighlighted, endPosOfStringToBeHighlighted);
                        }
                    }
                    stringToBeHighlighted = stringToBeHighlighted.replace("\"", "&quot;").replace("'", "&#39;");
                    debug("Searching to highlight the phrase:"+stringToBeHighlighted);
                    BookwormApp.Bookworm.onLoadJavaScript.append(" highlightText(encodeURIComponent('"+stringToBeHighlighted+"'));");
                }
            }
        }
        //complete the onload javascript string
        BookwormApp.Bookworm.onLoadJavaScript.append("\"");

        //add onload javascript and css to body tag
        if(pageContent.str.index_of("<BODY") != -1){
            pageContent.assign(pageContent.str.replace("<BODY", currentBookwormScripts + "<BODY " +
                                                                                            BookwormApp.Bookworm.onLoadJavaScript.str));
        }else if (pageContent.str.index_of("<body") != -1){
            pageContent.assign(pageContent.str.replace("<body", currentBookwormScripts + "<body " +
                                                                                            BookwormApp.Bookworm.onLoadJavaScript.str));
        }else{
            pageContent.assign(currentBookwormScripts + "<BODY " +
                                                BookwormApp.Bookworm.onLoadJavaScript.str + ">" +
                                                pageContent.str + "</BODY>");
        }
        //debug(pageContent.str);
        return pageContent.str;
    }

    public static void searchHTMLContents(){
        StringBuilder bookSearchResults = new StringBuilder ("");
        int searchResultCount = 1;
        BookwormApp.Bookworm.searchResultsMap.clear();
        //execute search
        bookSearchResults.assign(BookwormApp.Utils.execute_sync_command(BookwormApp.Constants.SEARCH_SCRIPT_LOCATION +
                                                    " \"" + BookwormApp.Bookworm.aContentFileToBeSearched.str + "\" \"" +
                                                    BookwormApp.AppHeaderBar.headerSearchBar.get_text() + "\""));
        //process search results
        if(bookSearchResults.str.strip().length > 0){
            string[] individualLines = bookSearchResults.str.strip().split ("\n",-1);
            foreach ( string individualLine in individualLines) {
                BookwormApp.Bookworm.searchResultsMap.set(searchResultCount.to_string()
                                            +"~~"+BookwormApp.Bookworm.aContentFileToBeSearched.str, individualLine.strip());
                searchResultCount++;
            }
        }
    }

    public static void refreshCurrentPage(){
        if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[1]){
            BookwormApp.Book currentBookForRefresh = BookwormApp.Bookworm.libraryViewMap.get (
                            BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
            currentBookForRefresh = renderPage(BookwormApp.Bookworm.libraryViewMap.get(
                            BookwormApp.Bookworm.locationOfEBookCurrentlyRead), "");
            BookwormApp.Bookworm.libraryViewMap.set(BookwormApp.Bookworm.locationOfEBookCurrentlyRead, currentBookForRefresh);
        }
    }

    public static int getScrollPos(){
        //This function is responsible for returning the vertical scroll position of the webview
        //This should be called when the user leaves reading a book :
        //(1) "Return" to Library button on Header Bar and (2) Close Bookworm while in reading mode
	    int scrollPos = -1;
        scrollPos = int.parse(BookwormApp.Utils.setWebViewTitle("document.title = window.scrollY;"));
        debug("Scroll position determined as:"+scrollPos.to_string());
	    return scrollPos;
    }

    public static void performStartUpActions(){
        //open the book added, if only one book path is present on command line
        //if this book was not in the library, then the library view will be shown
        if(BookwormApp.Bookworm.pathsOfBooksToBeAdded.length == 2 &&
            BookwormApp.Constants.bookworm_id == BookwormApp.Bookworm.pathsOfBooksToBeAdded[0])
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
                    BookwormApp.Book lastReadBook = BookwormApp.Bookworm.libraryViewMap.get(
                                BookwormApp.Bookworm.settings.book_being_read);
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
