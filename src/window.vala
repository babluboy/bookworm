/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and is used for drawing the
* window components for both the library view and the reading view
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
using Granite.Widgets;

public class BookwormApp.AppWindow {
  public static Gtk.InfoBar infobar;
  public static Gtk.Box bookLibrary_ui_box;
  public static Gtk.FlowBox library_grid;
  public static Gtk.Label infobarLabel;
  public static ScrolledWindow library_scroll;
  public static WebKit.WebView aWebView;
  public static Gtk.EventBox book_reading_footer_eventbox;
  public static Gtk.Box book_reading_footer_box;
  public static Gtk.Box bookReading_ui_box;
  public static Gtk.Button forward_button;
  public static Gtk.Button back_button;
  public static Gtk.ProgressBar bookAdditionBar;

  public static Gtk.Box createBoookwormUI() {
    debug("Starting to create main window components...");

    //Create a box to display the book library
    library_grid = new Gtk.FlowBox();
    library_grid.set_border_width (BookwormApp.Constants.SPACING_WIDGETS);
    library_grid.column_spacing = BookwormApp.Constants.SPACING_WIDGETS;
    library_grid.row_spacing = BookwormApp.Constants.SPACING_WIDGETS;
    library_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
    library_grid.homogeneous = true;
    library_grid.set_valign(Gtk.Align.START);

    library_scroll = new ScrolledWindow (null, null);
    library_scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
    library_scroll.add (library_grid);

    //Set up Button for selection of books
    Gtk.Image select_book_image = new Gtk.Image ();
    select_book_image.set_from_file (BookwormApp.Constants.SELECTION_IMAGE_BUTTON_LOCATION);
    Gtk.Button select_book_button = new Gtk.Button ();
    select_book_button.set_image (select_book_image);

    //Set up Button for adding books
    Gtk.Image add_book_image = new Gtk.Image ();
    add_book_image.set_from_file (BookwormApp.Constants.ADD_BOOK_ICON_IMAGE_LOCATION);
    Gtk.Button add_book_button = new Gtk.Button ();
    add_book_button.set_image (add_book_image);

    //Set up Button for removing books
    Gtk.Image remove_book_image = new Gtk.Image ();
    remove_book_image.set_from_file (BookwormApp.Constants.REMOVE_BOOK_ICON_IMAGE_LOCATION);
    Gtk.Button remove_book_button = new Gtk.Button ();
    remove_book_button.set_image (remove_book_image);

    //Set up the progress bar for addition of books to library
    bookAdditionBar = new Gtk.ProgressBar ();
    bookAdditionBar.set_valign(Gtk.Align.CENTER);
    bookAdditionBar.set_show_text (true);

    //Create a footer to select/add/remove books
    Gtk.Box add_remove_footer_box = new Gtk.Box (Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_BUTTONS);
    add_remove_footer_box.set_border_width(BookwormApp.Constants.SPACING_BUTTONS);
    //Set up contents of the add/remove books footer label
    add_remove_footer_box.pack_start (select_book_button, false, true, 0);
    add_remove_footer_box.pack_start (add_book_button, false, true, 0);
    add_remove_footer_box.pack_start (remove_book_button, false, true, 0);
    add_remove_footer_box.pack_end (bookAdditionBar, false, true, 0);

    //Create a MessageBar to show
    infobar = new Gtk.InfoBar ();
    infobarLabel = new Gtk.Label("");
    Gtk.Container infobarContent = infobar.get_content_area ();
    infobar.set_message_type (MessageType.INFO);
    infobarContent.add (infobarLabel);
    infobar.set_show_close_button (true);
    infobar.response.connect(BookwormApp.Bookworm.on_info_bar_closed);
    infobar.hide();

    //Create the UI for library view
    bookLibrary_ui_box = new Gtk.Box (Orientation.VERTICAL, BookwormApp.Constants.SPACING_WIDGETS);
    //add all components to ui box for library view
    bookLibrary_ui_box.pack_start (infobar, false, true, 0);
    bookLibrary_ui_box.pack_start (library_scroll, true, true, 0);
    bookLibrary_ui_box.pack_start (add_remove_footer_box, false, true, 0);

    //create the webview to display page content
    WebKit.Settings webkitSettings = new WebKit.Settings();
    webkitSettings.set_allow_file_access_from_file_urls (true);
    //webkitSettings.set_allow_universal_access_from_file_urls(true); //launchpad error
    webkitSettings.set_auto_load_images(true);
    aWebView = new WebKit.WebView.with_settings(webkitSettings);
    aWebView.set_zoom_level(BookwormApp.Settings.get_instance().zoom_level);
    webkitSettings.set_enable_javascript(true);

    //Set up Button for previous page
    Gtk.Image back_button_image = new Gtk.Image ();
    back_button_image.set_from_file (BookwormApp.Constants.PREV_PAGE_ICON_IMAGE_LOCATION);
    back_button = new Gtk.Button ();
    back_button.set_image (back_button_image);

    //Set up Button for next page
    Gtk.Image forward_button_image = new Gtk.Image ();
    forward_button_image.set_from_file (BookwormApp.Constants.NEXT_PAGE_ICON_IMAGE_LOCATION);
    forward_button = new Gtk.Button ();
    forward_button.set_image (forward_button_image);

    //Set up contents of the footer
    book_reading_footer_eventbox = new Gtk.EventBox ();
    book_reading_footer_box = new Gtk.Box (Orientation.HORIZONTAL, 0);
    Gtk.Label pageNumberLabel = new Label("");
    book_reading_footer_box.pack_start (back_button, false, true, 0);
    book_reading_footer_box.pack_start (pageNumberLabel, true, true, 0);
    book_reading_footer_box.pack_end (forward_button, false, true, 0);
    book_reading_footer_box.set_border_width(BookwormApp.Constants.SPACING_BUTTONS);
    book_reading_footer_eventbox.add(book_reading_footer_box);

    //Create the Gtk Box to hold components for reading a selected book
    bookReading_ui_box = new Gtk.Box (Orientation.VERTICAL, 0);
    bookReading_ui_box.pack_start (aWebView, true, true, 0);
    bookReading_ui_box.pack_start (book_reading_footer_eventbox, false, true, 0);

    //Add all ui components to the main UI box
    Gtk.Box main_ui_box = new Gtk.Box (Orientation.VERTICAL, 0);
    main_ui_box.pack_start(bookLibrary_ui_box, true, true, 0);
    main_ui_box.pack_start(BookwormApp.Info.createBookInfo(), true, true, 0);
    main_ui_box.pack_end(bookReading_ui_box, true, true, 0);
    main_ui_box.get_style_context().add_class ("box_white");

    //Add all UI action listeners

    //Add action on the forward button for reading
    forward_button.clicked.connect (() => {
      //get object for this ebook and call the next page
      BookwormApp.Book currentBookForForward = new BookwormApp.Book();
      currentBookForForward = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
      debug("Initiating read forward for eBook:"+currentBookForForward.getBookLocation());
      currentBookForForward = BookwormApp.Bookworm.renderPage(currentBookForForward, "FORWARD");
      currentBookForForward = BookwormApp.Bookworm.controlNavigation(currentBookForForward);
      //update book details to libraryView Map
      BookwormApp.Bookworm.libraryViewMap.set(currentBookForForward.getBookLocation(), currentBookForForward);
      BookwormApp.Bookworm.locationOfEBookCurrentlyRead = currentBookForForward.getBookLocation();
    });
    //Add action on the backward button for reading
    back_button.clicked.connect (() => {
      //get object for this ebook and call the next page
      BookwormApp.Book currentBookForReverse = new BookwormApp.Book();
      currentBookForReverse = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
      debug("Initiating read previous for eBook:"+currentBookForReverse.getBookLocation());
      currentBookForReverse = BookwormApp.Bookworm.renderPage(currentBookForReverse, "BACKWARD");
      currentBookForReverse = BookwormApp.Bookworm.controlNavigation(currentBookForReverse);
      //update book details to libraryView Map
      BookwormApp.Bookworm.libraryViewMap.set(currentBookForReverse.getBookLocation(), currentBookForReverse);
      BookwormApp.Bookworm.locationOfEBookCurrentlyRead = currentBookForReverse.getBookLocation();
    });
    //Add action for adding a book on the library view
    add_book_button.clicked.connect (() => {
      ArrayList<string> selectedEBooks = BookwormApp.Utils.selectBookFileChooser();
      BookwormApp.Bookworm.pathsOfBooksToBeAdded = new string[selectedEBooks.size];
      int countOfBooksToBeAdded = 0;
      foreach(string pathToSelectedBook in selectedEBooks){
        BookwormApp.Bookworm.pathsOfBooksToBeAdded[countOfBooksToBeAdded] = pathToSelectedBook;
        countOfBooksToBeAdded++;
      }
      //Display the progress bar
			BookwormApp.AppWindow.bookAdditionBar.show();
			BookwormApp.Bookworm.isBookBeingAddedToLibrary = true;
      BookwormApp.Bookworm.addBooksToLibrary ();
    });
    //Add action for putting library in select view
    select_book_button.clicked.connect (() => {
      //check if the mode is already in selection mode
      if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[2] || BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[3]){
        //UI is already in selection/selected mode - second click puts the view in normal mode
        BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[0];
        BookwormApp.Bookworm.updateLibraryViewForSelectionMode(null);
      }else{
        //UI is not in selection/selected mode - set the view mode to selection mode
        BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[2];
        BookwormApp.Bookworm.updateLibraryViewForSelectionMode(null);
      }
    });

    //Add action for removing a selected book on the library view
    remove_book_button.clicked.connect (() => {
      BookwormApp.Bookworm.removeSelectedBooksFromLibrary();
    });
    //handle context menu on the webview reader
    aWebView.context_menu.connect (() => {
      //TO-DO: Build context menu for reading ebook
      return true;//stops webview default context menu from loading
    });
    //capture key press events on the webview reader
    aWebView.key_press_event.connect ((ev) => {
        if (ev.keyval == Gdk.Key.Left) {// Left Key pressed, move page backwards
          //get object for this ebook
          BookwormApp.Book aBookLeftKeyPress = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
          aBookLeftKeyPress = BookwormApp.Bookworm.renderPage(aBookLeftKeyPress, "BACKWARD");
          aBookLeftKeyPress = BookwormApp.Bookworm.controlNavigation(aBookLeftKeyPress);
          //update book details to libraryView Map
          BookwormApp.Bookworm.libraryViewMap.set(aBookLeftKeyPress.getBookLocation(), aBookLeftKeyPress);
        }
        if (ev.keyval == Gdk.Key.Right) {// Right key pressed, move page forward
          //get object for this ebook
          BookwormApp.Book aBookRightKeyPress = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
          aBookRightKeyPress = BookwormApp.Bookworm.renderPage(aBookRightKeyPress, "FORWARD");
          aBookRightKeyPress = BookwormApp.Bookworm.controlNavigation(aBookRightKeyPress);
          //update book details to libraryView Map
          BookwormApp.Bookworm.libraryViewMap.set(aBookRightKeyPress.getBookLocation(), aBookRightKeyPress);
        }
        return false;
    });
    //capture the url clicked on the webview and action the navigation type clicks
    aWebView.decide_policy.connect ((decision, type) => {
      if(type == WebKit.PolicyDecisionType.NAVIGATION_ACTION){
        WebKit.NavigationPolicyDecision aNavDecision = (WebKit.NavigationPolicyDecision)decision;
        WebKit.NavigationAction aNavAction = aNavDecision.get_navigation_action();
        WebKit.URIRequest aURIReq = aNavAction.get_request ();

        BookwormApp.Book aBook = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
        string url_clicked_on_webview = BookwormApp.Utils.decodeHTMLChars(aURIReq.get_uri().strip());
        debug("URL Captured:"+url_clicked_on_webview);
        if (url_clicked_on_webview.index_of("#") != -1){
          url_clicked_on_webview = url_clicked_on_webview.slice(0, url_clicked_on_webview.index_of("#"));
        }
        url_clicked_on_webview = File.new_for_path(url_clicked_on_webview).get_basename();
        int contentLocationPosition = 0;
        foreach (string aBookContent in aBook.getBookContentList()) {
          if(BookwormApp.Utils.decodeHTMLChars(aBookContent).index_of(url_clicked_on_webview) != -1){
            debug("Matched Link Clicked to book content:"+BookwormApp.Utils.decodeHTMLChars(aBookContent));
            aBook.setBookPageNumber(contentLocationPosition);
            //update book details to libraryView Map
            BookwormApp.Bookworm.libraryViewMap.set(aBook.getBookLocation(), aBook);
            aBook = BookwormApp.Bookworm.renderPage(aBook, "");
            //Set the mode back to Reading mode
            BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[1];
            BookwormApp.Bookworm.toggleUIState();
            debug("URL is initiated from Bookworm Contents, Book page number set at:"+aBook.getBookPageNumber().to_string());
            break;
          }
          contentLocationPosition++;
        }
      }
      return true;
    });

    debug("Completed creation of main window components...");
    return main_ui_box;
  }

  public static Granite.Widgets.Welcome createWelcomeScreen(){
    //Create a welcome screen for view of library with no books
    BookwormApp.Bookworm.welcomeWidget = new Granite.Widgets.Welcome (BookwormApp.Constants.TEXT_FOR_WELCOME_MESSAGE_TITLE, BookwormApp.Constants.TEXT_FOR_WELCOME_MESSAGE_SUBTITLE);
    Gtk.Image? openFolderImage = new Gtk.Image.from_icon_name("document-open", Gtk.IconSize.DIALOG);
    BookwormApp.Bookworm.welcomeWidget.append_with_image (openFolderImage, "Open", BookwormApp.Constants.TEXT_FOR_WELCOME_OPENDIR_MESSAGE);

    //Add action for adding a book on the library view
    BookwormApp.Bookworm.welcomeWidget.activated.connect (() => {
      //remove the welcome widget from main window
      BookwormApp.Bookworm.window.remove(BookwormApp.Bookworm.welcomeWidget);
      BookwormApp.Bookworm.window.add(BookwormApp.Bookworm.bookWormUIBox);
      BookwormApp.Bookworm.bookWormUIBox.show_all();
      BookwormApp.Bookworm.toggleUIState();

      ArrayList<string> selectedEBooks = BookwormApp.Utils.selectBookFileChooser();
      BookwormApp.Bookworm.pathsOfBooksToBeAdded = new string[selectedEBooks.size];
      int countOfBooksToBeAdded = 0;
      foreach(string pathToSelectedBook in selectedEBooks){
        BookwormApp.Bookworm.pathsOfBooksToBeAdded[countOfBooksToBeAdded] = pathToSelectedBook;
        countOfBooksToBeAdded++;
      }
      //Display the progress bar
			BookwormApp.AppWindow.bookAdditionBar.show();
			BookwormApp.Bookworm.isBookBeingAddedToLibrary = true;
      BookwormApp.Bookworm.addBooksToLibrary ();
    });
    return BookwormApp.Bookworm.welcomeWidget;
  }
}
