/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and serves as the UI for Book metadata
* information like Table of Contents, Bookmarks
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
using Gtk;
using Gee;
public class BookwormApp.Info:Gtk.Window {
  public static Box info_box;
  public static Gtk.Stack stack;
  public static Box content_box;
  public static ScrolledWindow content_scroll;
  public static Box bookmarks_box;
  public static ScrolledWindow bookmarks_scroll;
  public static Box searchresults_box;
  public static ScrolledWindow searchresults_scroll;
  public static Box annotations_box;
  public static ScrolledWindow annotations_scroll;
  public static Box dictionary_box;
  public static Gtk.Label dictionaryResultsLabel;
  public static ScrolledWindow dictionary_scroll;
  public static LinkButton firstSearchResultLinkButton;

  public static Gtk.Box createBookInfo(){
    info("[START] [FUNCTION:createBookInfo]");
    info_box = new Gtk.Box (Orientation.VERTICAL, BookwormApp.Constants.SPACING_WIDGETS);
    info_box.set_border_width(BookwormApp.Constants.SPACING_WIDGETS);

    //define the stack for the tabbed view
    stack = new Gtk.Stack();
    stack.set_transition_type(StackTransitionType.SLIDE_LEFT_RIGHT);
    stack.set_transition_duration(1000);

    //define the switcher for switching between tabs
    StackSwitcher switcher = new StackSwitcher();
    switcher.set_halign(Align.CENTER);
    switcher.set_stack(stack);

    content_box = new Gtk.Box (Orientation.VERTICAL, BookwormApp.Constants.SPACING_WIDGETS);
    content_scroll = new ScrolledWindow (null, null);
    content_scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
    content_scroll.add (content_box);
    stack.add_titled(content_scroll, "content-list", BookwormApp.Constants.TEXT_FOR_INFO_TAB_CONTENTS);

    bookmarks_box = new Gtk.Box (Orientation.VERTICAL, BookwormApp.Constants.SPACING_WIDGETS);
    bookmarks_scroll = new ScrolledWindow (null, null);
    bookmarks_scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
    bookmarks_scroll.add (bookmarks_box);
    stack.add_titled(bookmarks_scroll, "bookmark-list", BookwormApp.Constants.TEXT_FOR_INFO_TAB_BOOKMARKS);

    searchresults_box = new Gtk.Box (Orientation.VERTICAL, BookwormApp.Constants.SPACING_WIDGETS);
    searchresults_scroll = new ScrolledWindow (null, null);
    searchresults_scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
    searchresults_scroll.add (searchresults_box);
    stack.add_titled(searchresults_scroll, "searchresults-list", BookwormApp.Constants.TEXT_FOR_INFO_TAB_SEARCHRESULTS);

    annotations_box = new Gtk.Box (Orientation.VERTICAL, BookwormApp.Constants.SPACING_WIDGETS);
    annotations_scroll = new ScrolledWindow (null, null);
    annotations_scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
    annotations_scroll.add (annotations_box);
    stack.add_titled(annotations_scroll, "annotations-list", BookwormApp.Constants.TEXT_FOR_INFO_TAB_ANNOTATIONS);
    
    dictionaryResultsLabel = new Label(BookwormApp.Constants.TEXT_FOR_DICTIONARY_LOOKUP_TEXT);
    dictionary_box = new Gtk.Box (Orientation.VERTICAL, BookwormApp.Constants.SPACING_WIDGETS);
    dictionary_box.pack_start(dictionaryResultsLabel,false,false,0);
    dictionary_scroll = new ScrolledWindow (null, null);
    dictionary_scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
    dictionary_scroll.add (dictionary_box);
    stack.add_titled(dictionary_scroll, "dictionary-list", BookwormApp.Constants.TEXT_FOR_INFO_TAB_DICTRESULTS);

    info_box.pack_start(switcher, false, true, 0);
    info_box.pack_start(stack, true, true, 0);

    //Check every time a tab is clicked and perform necessary actions
    stack.notify["visible-child"].connect ((sender, property) => {
      if("content-list"==stack.get_visible_child_name()){
        createTableOfContents();
      }
      if("bookmark-list"==stack.get_visible_child_name()){
        populateBookmarks();
      }
      if("annotations-list"==stack.get_visible_child_name()){
        populateAnnotations();
      }
      if("searchresults-list"==stack.get_visible_child_name()){
        //This is called from the header search bar
        if(firstSearchResultLinkButton != null){
          firstSearchResultLinkButton.grab_focus(); //sets the focus on the first link
        }
      }
      if("dictionary-list"==stack.get_visible_child_name()){
        //This is called from the context menu
      }
      //Set the value of the info tab currently being viewed so that the same tab is opened subsequently
      BookwormApp.Bookworm.settings.current_info_tab = stack.get_visible_child_name();
    });
    info("[END] [FUNCTION:createBookInfo]");
    return info_box;
  }

  public static void populateAnnotations(){
    info("[START] [FUNCTION:populateAnnotations]");
    //get the book being currently read
	BookwormApp.Book aBook = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
    Gtk.Label annotationsLabel = new Label(BookwormApp.Constants.TEXT_FOR_ANNOTATIONS_FOUND);
    Box annotations_box = new Box (Orientation.VERTICAL, BookwormApp.Constants.SPACING_WIDGETS);
    annotations_box.pack_start(annotationsLabel,false,false,0);
    TreeMap<string,string> aAnnotationMap = aBook.getAnnotationList();
    if(aAnnotationMap != null && aAnnotationMap.size > 0){
      foreach (var entry in aAnnotationMap.ascending_entries){
          LinkButton annotationLinkButton = new LinkButton.with_label (
                                                                            entry.key.strip().split("#~~#")[0],
                                                                            "Section " + entry.key.strip().split("#~~#")[0] +
                                                                            " [" +    BookwormApp.Utils.minimizeStringLength(
                                                                                                    entry.key.strip().split("#~~#")[1].replace("\n", " "),
                                                                                                    BookwormApp.Constants.MAX_NUMBER_OF_CHARS_FOR_ANNOTATION_TAB) +
                                                                             "] : " + BookwormApp.Utils.minimizeStringLength(
                                                                                                    entry.value.strip().replace("\n", " "),
                                                                                                    BookwormApp.Constants.MAX_NUMBER_OF_CHARS_FOR_ANNOTATION_TAB));
          annotationLinkButton.halign = Align.START;
          annotations_box.pack_start(annotationLinkButton,false,false,0);
          annotationLinkButton.activate_link.connect (() => {
                aBook.setBookPageNumber(int.parse(annotationLinkButton.get_uri ().strip()));
                //update book details to libraryView Map
                BookwormApp.Bookworm.libraryViewMap.set(aBook.getBookLocation(), aBook);
                aBook = BookwormApp.contentHandler.renderPage(aBook, "");
                //Set the mode back to Reading mode
                BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[1];
                BookwormApp.Bookworm.toggleUIState();
                return true;
          });
        }
    }else{
      annotationsLabel.set_text(BookwormApp.Constants.TEXT_FOR_ANNOTATIONS_NOT_FOUND.replace("BBB", aBook.getBookTitle()));
    }
    //Remove the existing annotations Gtk.Box and add the current one
    annotations_scroll.get_child().destroy();
    annotations_scroll.add (annotations_box);
    annotations_box.show_all();
    info("[END] [FUNCTION:populateAnnotations]");
  }

  public static void populateBookmarks(){
    info("[START] [FUNCTION:populateBookmarks]");
    //get the book being currently read
	BookwormApp.Book aBook = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
    Box bookmarks_box = new Box (Orientation.VERTICAL, BookwormApp.Constants.SPACING_WIDGETS);
    Gtk.Label bookmarksLabel = new Label(BookwormApp.Constants.TEXT_FOR_BOOKMARKS_FOUND);
    bookmarks_box.pack_start(bookmarksLabel,false,false,0);
    if(aBook.getBookmark().index_of("**") != -1){
      string[] bookmarkList = aBook.getBookmark().split_set("**", -1);
      int bookmarkNumber = 1;
      foreach (string bookmarkedPage in bookmarkList) {
        if(bookmarkedPage != null && bookmarkedPage.length > 0){
          LinkButton bookmarkLinkButton = new LinkButton.with_label (bookmarkedPage,
                BookwormApp.Constants.TEXT_FOR_BOOKMARKS
                                .replace("NNN", bookmarkNumber.to_string())
                                .replace("PPP", (int.parse(bookmarkedPage)+1).to_string()));
          bookmarkNumber++;
          bookmarkLinkButton.halign = Align.START;
          bookmarks_box.pack_start(bookmarkLinkButton,false,false,0);
          bookmarkLinkButton.activate_link.connect (() => {
            aBook.setBookPageNumber(int.parse(bookmarkLinkButton.get_uri ().strip()));
            //update book details to libraryView Map
            BookwormApp.Bookworm.libraryViewMap.set(aBook.getBookLocation(), aBook);
            aBook = BookwormApp.contentHandler.renderPage(aBook, "");
            //Set the mode back to Reading mode
            BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[1];
            BookwormApp.Bookworm.toggleUIState();
            return true;
          });
        }
      }
    }else{
      bookmarksLabel.set_text(BookwormApp.Constants.TEXT_FOR_BOOKMARKS_NOT_FOUND.replace("BBB", aBook.getBookTitle()));
    }
    //Remove the existing search results Gtk.Box and add the current one
    bookmarks_scroll.get_child().destroy();
    bookmarks_scroll.add (bookmarks_box);
    info_box.show_all();
     info("[END] [FUNCTION:populateBookmarks]");
  }
  
  public static void populateDictionaryResults(string word){
    info("[START] [FUNCTION:populateDictionaryResults]");
    //Create the Gtk.Box for displaying results
    Box dictionary_box = new Box (Orientation.VERTICAL, BookwormApp.Constants.SPACING_WIDGETS);
    dictionaryResultsLabel = new Label("");
    dictionary_box.pack_start(dictionaryResultsLabel,false,false,0);
    //Remove the existing dictionary results Gtk.Box and add the current one
    dictionary_scroll.get_child().destroy();
    dictionary_scroll.add (dictionary_box);
    string dictionaryResults = "";
    //Show help text if no word is available for dictionary lookup
    debug(word);
    if(word == null || word.strip().length < 1){
            dictionaryResultsLabel.set_text( BookwormApp.Constants.TEXT_FOR_DICTIONARY_LOOKUP_TEXT);
    }else{
            //Perform book search only if the Reading View is active
            if(
                BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[1]
            ){
                //Set the mode to Info View Mode
                BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[4];
                BookwormApp.Bookworm.toggleUIState();
                //Set the visible tab to search result tab
                BookwormApp.Info.stack.set_visible_child (BookwormApp.Info.stack.get_child_by_name ("dictionary-list"));
            }
                
            //Ensure that the word search script is installed
            if("true" != BookwormApp.Utils.fileOperations(
                                "EXISTS", 
                                BookwormApp.Bookworm.bookworm_config_path, 
                                BookwormApp.Constants.DICTIONARY_SCRIPT_INSTALL_LOCATION, "")
            ){
                //get contents from gresource
                uint8[] bookwormDictionaryData;
                GLib.File.new_for_uri(BookwormApp.Constants.DICTIONARY_SCRIPT_RESOURCE_LOCATION)
			                                            .load_contents(null, out bookwormDictionaryData, null);
                string dictionaryScripts = (string) bookwormDictionaryData;
                //create scripts directory
                BookwormApp.Utils.fileOperations(
                            "CREATEDIR", 
                            BookwormApp.Bookworm.bookworm_config_path+"/scripts/", "", "");
                //write data to filename
                BookwormApp.Utils.fileOperations(
                            "WRITE", 
                            BookwormApp.Bookworm.bookworm_config_path, 
                            BookwormApp.Constants.DICTIONARY_SCRIPT_INSTALL_LOCATION, 
                            dictionaryScripts);
                //make file executable
                BookwormApp.Utils.fileOperations(
                            "MAKE_EXECUTABLE", 
                            BookwormApp.Bookworm.bookworm_config_path, 
                            BookwormApp.Constants.DICTIONARY_SCRIPT_INSTALL_LOCATION, 
                            "");
            }
            //Execute word meaning script - invokes online/offline dictionary
            dictionaryResults = BookwormApp.Utils.execute_sync_command (
                                                                    BookwormApp.Bookworm.bookworm_config_path + 
                                                                    BookwormApp.Constants.DICTIONARY_SCRIPT_INSTALL_LOCATION +
                                                                    " " + word
                                                            );
            debug ("Dictionary Search Results:" + dictionaryResults);
            dictionaryResultsLabel.set_text(dictionaryResults);
    }
    
    info_box.show_all();
    info("[END] [FUNCTION:populateDictionaryResults]");
  }

  public static async BookwormApp.Book populateSearchResults(){
    info("[START] [FUNCTION:populateSearchResults]");
    BookwormApp.Book aBook = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
    Box searchresults_box = new Box (Orientation.VERTICAL, BookwormApp.Constants.SPACING_WIDGETS);
    bool hasResultsBeenFound = false;
    bool isSearchResultFocussed = false;

    Gtk.Label searchLabel = new Label(BookwormApp.Constants.TEXT_FOR_SEARCH_RESULTS_PROCESSING
                                                                                        .replace("$$$", BookwormApp.Utils.minimizeStringLength
                                                                                                                     (BookwormApp.AppHeaderBar.headerSearchBar.get_text(), 50))
                                                                                        .replace("&&&", BookwormApp.Utils.minimizeStringLength(aBook.getBookTitle(), 35)));
    searchresults_box.pack_start(searchLabel,false,false,0);

    //Remove the existing search results Gtk.Box and add the current one
    searchresults_scroll.get_child().destroy();
    searchresults_scroll.add (searchresults_box);

    //Loop through each html file of the book and search for content
    foreach (string aBookContentFile in aBook.getBookContentList()) {
      //Add callback to join back the loop after releasing control
      Idle.add (populateSearchResults.callback);

      BookwormApp.Bookworm.aContentFileToBeSearched.assign(aBookContentFile);
      BookwormApp.contentHandler.searchHTMLContents();
      //Add link buttons representing the search results - if found
      if(BookwormApp.Bookworm.searchResultsMap.size > 0){
        hasResultsBeenFound = true;
        foreach (var entry in BookwormApp.Bookworm.searchResultsMap.ascending_entries) {
            string pageNumber = entry.key.slice(entry.key.index_of("~~")+2, entry.key.length).strip();
            LinkButton searchResultLinkButton = new LinkButton.with_label (pageNumber,  BookwormApp.Utils.parseMarkUp(
                                                                                   getChapterNameFromPage(pageNumber)+" : "+
                                                                                   BookwormApp.Utils.minimizeStringLength(entry.value, 100)));
            searchResultLinkButton.halign = Align.START;
            searchresults_box.pack_start(searchResultLinkButton,false,false,0);
            //grab the focus on the first search result
            if(!isSearchResultFocussed){
                searchResultLinkButton.grab_focus();
                isSearchResultFocussed = true;
                firstSearchResultLinkButton = searchResultLinkButton;
            }
            searchResultLinkButton.activate_link.connect (() => {
            aBook.setBookPageNumber(aBook.getBookContentList().index_of(searchResultLinkButton.get_uri ().strip()));
            //update book details to libraryView Map
            BookwormApp.Bookworm.libraryViewMap.set(aBook.getBookLocation(), aBook);
            BookwormApp.Bookworm.bookTextSearchString = BookwormApp.AppHeaderBar.headerSearchBar.get_text() +
                                                                                                   "#~~#" + searchResultLinkButton.get_label();
            aBook = BookwormApp.contentHandler.renderPage(aBook, "SEARCH");
            //Set the mode back to Reading mode
            BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[1];
            BookwormApp.Bookworm.toggleUIState();
            return true;
          });
        }
      }
      searchresults_box.show_all();
      //release back control to UI
      yield;
    }
    //Set the text based on whether results have been found or not
    if(hasResultsBeenFound){
      searchLabel.set_text(BookwormApp.Constants.TEXT_FOR_SEARCH_RESULTS_FOUND
                                                                                        .replace("$$$", BookwormApp.Utils.minimizeStringLength
                                                                                                                     (BookwormApp.AppHeaderBar.headerSearchBar.get_text(), 50))
                                                                                        .replace("&&&", BookwormApp.Utils.minimizeStringLength(aBook.getBookTitle(), 35)));
    }else{
      searchLabel.set_text(BookwormApp.Constants.TEXT_FOR_SEARCH_RESULTS_NOT_FOUND
                                                                                        .replace("$$$", BookwormApp.Utils.minimizeStringLength
                                                                                                                     (BookwormApp.AppHeaderBar.headerSearchBar.get_text(), 50))
                                                                                        .replace("&&&", BookwormApp.Utils.minimizeStringLength(aBook.getBookTitle(), 35)));
    }
    info("[END] [FUNCTION:populateSearchResults]");
    return aBook;
  }

  public static string getChapterNameFromPage(string pageNumber){
    debug("[START] [FUNCTION:getChapterNameFromPage] pageNumber="+pageNumber);
    string chapterName = "";
    //get the book being currently read
		BookwormApp.Book aBook = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
    if(aBook != null){
      int indexOfPageInContentList = aBook.getBookContentList().index_of(pageNumber);
      int indexOfCurrentChapterInContentList = 0;
      string previousChapterName = "";
      ArrayList<HashMap<string,string>> tocList = aBook.getTOC();
      foreach(HashMap<string,string> tocListItemMap in tocList){
        foreach (var entry in tocListItemMap.entries) {
          indexOfCurrentChapterInContentList = aBook.getBookContentList().index_of(entry.key);
          if(entry.key == pageNumber){
            chapterName =  entry.value; //search result page is a chapter page
            break;
          }else{
            if(indexOfCurrentChapterInContentList > indexOfPageInContentList){
              chapterName =  previousChapterName; //search result page is prior to the current chapter page - so assign previous chapter page
              break;
            }
          }
          previousChapterName = entry.value;
        }
        if(chapterName.length > 0){
            break;
        }
      }
      //handle the case when no chapter name has been selected
      if(chapterName.length < 1){
        chapterName = "Section " + pageNumber;
      }
    }
    debug("[END] [FUNCTION:getChapterNameFromPage] chapterName="+chapterName);
    return chapterName;
  }

  public static BookwormApp.Book createTableOfContents(){
    info("[START] [FUNCTION:createTableOfContents]");
    Box content_box;
    //get the book being currently read
	BookwormApp.Book aBook = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
    if(aBook != null){
      //Return TOC if it has already been determined for the book - otherwise create TOC for the book
      if(aBook.getBookWidget("TABLE_OF_CONTENTS_WIDGET") != null){
        content_box = (Gtk.Box) (aBook.getBookWidget("TABLE_OF_CONTENTS_WIDGET"));
        debug("found TABLE_OF_CONTENTS_WIDGET");
      }else{
        content_box = new Box (Orientation.VERTICAL, BookwormApp.Constants.SPACING_WIDGETS);
        //Use Table Of Contents if present
        if(aBook.getTOC().size > 0){
          ArrayList<HashMap<string,string>> tocList = aBook.getTOC();
          foreach(HashMap<string,string> tocListItemMap in tocList){
            foreach (var entry in tocListItemMap.entries) {
              LinkButton contentLinkButton = new LinkButton.with_label (entry.key, BookwormApp.Utils.parseMarkUp(entry.value));
              contentLinkButton.halign = Align.START;
              content_box.pack_start(contentLinkButton,false,false,0);
              contentLinkButton.activate_link.connect (() => {
                string linkURI = contentLinkButton.get_uri ().strip();
                //check if the link contains a # - bookmarked section
                if(linkURI.index_of("#") != -1){
                    string URIWithoutBookmark = linkURI.slice(0, linkURI.last_index_of("#"));
                    aBook.setBookPageNumber(aBook.getBookContentList().index_of(URIWithoutBookmark));
                    aBook.setAnchor(linkURI.slice(linkURI.last_index_of("#")+1, linkURI.length));
                    BookwormApp.Bookworm.isPageScrollRequired = true;
                }else{
                    aBook.setBookPageNumber(aBook.getBookContentList().index_of(linkURI));
                }
                debug("Selected link from Table of Contents with URI ["+linkURI+"] and page location:"+aBook.getBookLocation().to_string());
                //update book details to libraryView Map
                BookwormApp.Bookworm.libraryViewMap.set(aBook.getBookLocation(), aBook);
                aBook = BookwormApp.contentHandler.renderPage(aBook, "");
                //Set the mode back to Reading mode
                BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[1];
                BookwormApp.Bookworm.toggleUIState();
                return true;
              });
            }
          }
        }else{
          //If Table Of Contents is not found, use the spine data
          int contentNumber = 1;
          foreach(string contentPath in aBook.getBookContentList()){
            LinkButton contentLinkButton = new LinkButton.with_label (contentPath,
                                BookwormApp.Constants.TEXT_FOR_INFO_TAB_CONTENT_PREFIX+contentNumber.to_string());
            contentLinkButton.halign = Align.START;
            content_box.pack_start(contentLinkButton,false,false,0);
            //add to the table of contents of the book
            HashMap<string,string> TOCMapItem = new HashMap<string,string>();
            TOCMapItem.set(contentPath, BookwormApp.Constants.TEXT_FOR_INFO_TAB_CONTENT_PREFIX+contentNumber.to_string());
            aBook.setTOC(TOCMapItem);
            contentNumber++;
            //add the action for the link button
            contentLinkButton.activate_link.connect (() => {
              aBook.setBookPageNumber(aBook.getBookContentList().index_of(contentLinkButton.get_uri ()));
              //update book details to libraryView Map
              BookwormApp.Bookworm.libraryViewMap.set(aBook.getBookLocation(), aBook);
              aBook = BookwormApp.contentHandler.renderPage(aBook, "");
              //Set the mode back to Reading mode
              BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[1];
              BookwormApp.Bookworm.toggleUIState();
              return true;
            });
          }
        }
        aBook.setBookWidget("TABLE_OF_CONTENTS_WIDGET", content_box);
      }
      //remove the current content widget from any existing parent (ViewPort is a default parent while adding to ScrollWindow)
      content_box.unparent ();
      if(content_scroll.get_child() != null){
        //add a ref to the existing content widget so that it is not destoyed on removal
        content_scroll.get_child().@ref();
        //remove the existing content widget from the ScrollWindow
        content_scroll.remove(content_scroll.get_child());
        //add the current content widget to the ScrollWindow
        content_scroll.add (content_box);
      }else{
        //No existing widget in the ScrollWindow, add the current content widget
        content_scroll.add (content_box);
      }
    }
    info("[END] [FUNCTION:createTableOfContents]");
    return aBook;
  }
}
