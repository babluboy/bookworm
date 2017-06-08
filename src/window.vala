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
  public static Gtk.ListStore library_table_liststore;
  public static TreeIter library_table_iter;
  public static Gtk.TreeView library_table_treeview;
  public static Gtk.Label infobarLabel;
  public static ScrolledWindow library_grid_scroll;
  public static ScrolledWindow library_list_scroll;
  public static WebKit.WebView aWebView;
  public static WebKit.Settings webkitSettings;
  public static Gtk.EventBox book_reading_footer_eventbox;
  public static Gtk.Box book_reading_footer_box;
  public static Gtk.Box bookReading_ui_box;
  public static Gtk.Button forward_button;
  public static Gtk.Button back_button;
  public static Gtk.ProgressBar bookAdditionBar;
  public static Adjustment pageAdjustment;
  public static Scale pageSlider;
  public static BookwormApp.Settings settings;

  public static Gtk.Box createBoookwormUI() {
    debug("Starting to create main window components...");
    settings = BookwormApp.Settings.get_instance();

    //Create a grid to display the book library
    library_grid = new Gtk.FlowBox();
    library_grid.set_border_width (BookwormApp.Constants.SPACING_WIDGETS);
    library_grid.column_spacing = BookwormApp.Constants.SPACING_WIDGETS;
    library_grid.row_spacing = BookwormApp.Constants.SPACING_WIDGETS;
    library_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
    library_grid.homogeneous = true;
    library_grid.set_valign(Gtk.Align.START);
    library_grid.set_filter_func(BookwormApp.Library.libraryViewFilter);

    library_grid_scroll = new ScrolledWindow (null, null);
    library_grid_scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
    library_grid_scroll.add (library_grid);

    //Create a treeview and Liststore to display the list of books in the library
    library_table_liststore = new Gtk.ListStore (8, typeof (Gdk.Pixbuf), typeof (string), typeof (string), typeof (string), typeof (Gdk.Pixbuf), typeof (string), typeof (string), typeof (string));
    library_table_treeview = new Gtk.TreeView();
    library_table_treeview.activate_on_single_click = true;
    //Set up the various cell types for the library metadata
    CellRendererPixbuf selection_cell_pix = new CellRendererPixbuf ();
    CellRendererText non_editable_cell_txt = new CellRendererText ();
    CellRendererText title_cell_txt = new CellRendererText ();
    title_cell_txt.editable = true;
    CellRendererText author_cell_txt = new CellRendererText ();
    author_cell_txt.editable = true;
    CellRendererPixbuf rating_cell_pix = new CellRendererPixbuf ();
    CellRendererText tags_cell_txt = new CellRendererText ();
    tags_cell_txt.editable = true;
    //Set up Treeview columns
    library_table_treeview.insert_column_with_attributes (-1, " ", selection_cell_pix, "pixbuf", 0);
    library_table_treeview.insert_column_with_attributes (-1, BookwormApp.Constants.TEXT_FOR_LIST_VIEW_COLUMN_NAME_TITLE, title_cell_txt, "text", 1);
		library_table_treeview.insert_column_with_attributes (-1, BookwormApp.Constants.TEXT_FOR_LIST_VIEW_COLUMN_NAME_AUTHOR, author_cell_txt, "text", 2);
		library_table_treeview.insert_column_with_attributes (-1, BookwormApp.Constants.TEXT_FOR_LIST_VIEW_COLUMN_NAME_MODIFIED_DATE, non_editable_cell_txt, "text", 3);
		library_table_treeview.insert_column_with_attributes (-1, BookwormApp.Constants.TEXT_FOR_LIST_VIEW_COLUMN_NAME_RATING, rating_cell_pix, "pixbuf", 4);
		library_table_treeview.insert_column_with_attributes (-1, BookwormApp.Constants.TEXT_FOR_LIST_VIEW_COLUMN_NAME_TAGS, tags_cell_txt, "text", 5);

    library_list_scroll = new ScrolledWindow (null, null);
    library_list_scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
    library_list_scroll.add (library_table_treeview);

    //Set up Button for selection of books
    Gtk.Image select_book_image = new Gtk.Image.from_icon_name ("object-select-symbolic", Gtk.IconSize.MENU);
    Gtk.Button select_book_button = new Gtk.Button ();
    select_book_button.set_image (select_book_image);
    select_book_button.set_relief (ReliefStyle.NONE);
    select_book_button.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_SELECT_BOOK);

    //Set up Button for adding books
    Gtk.Image add_book_image = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU);
    Gtk.Button add_book_button = new Gtk.Button ();
    add_book_button.set_image (add_book_image);
    add_book_button.set_relief (ReliefStyle.NONE);
    add_book_button.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_ADD_BOOK);

    //Set up Button for removing books
    Gtk.Image remove_book_image = new Gtk.Image.from_icon_name ("list-remove-symbolic", Gtk.IconSize.MENU);
    Gtk.Button remove_book_button = new Gtk.Button ();
    remove_book_button.set_image (remove_book_image);
    remove_book_button.set_relief (ReliefStyle.NONE);
    remove_book_button.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_REMOVE_BOOK);

    //Set up the progress bar for addition of books to library
    bookAdditionBar = new Gtk.ProgressBar ();
    bookAdditionBar.set_valign(Gtk.Align.CENTER);
    bookAdditionBar.set_show_text (true);

    //Create a footer and add widgets for select/add/remove books
    ActionBar add_remove_footer_box = new ActionBar();
    add_remove_footer_box.pack_start (select_book_button);
    add_remove_footer_box.pack_start (add_book_button);
    add_remove_footer_box.pack_start (remove_book_button);
    add_remove_footer_box.pack_end (bookAdditionBar);

    //Create a MessageBar to show
    infobar = new Gtk.InfoBar ();
    infobarLabel = new Gtk.Label("");
    Gtk.Container infobarContent = infobar.get_content_area ();
    infobar.set_message_type (MessageType.INFO);
    infobarContent.add (infobarLabel);
    infobar.set_show_close_button (true);
    infobar.response.connect(on_info_bar_closed);
    infobar.hide();

    //Create the UI for library view and add all components to ui box for library view
    bookLibrary_ui_box = new Gtk.Box (Orientation.VERTICAL, BookwormApp.Constants.SPACING_WIDGETS);
    bookLibrary_ui_box.set_border_width (0);
    bookLibrary_ui_box.pack_start (infobar, false, true, 0);
    bookLibrary_ui_box.pack_start (library_grid_scroll, true, true, 0);
    bookLibrary_ui_box.pack_start (library_list_scroll, true, true, 0);
    bookLibrary_ui_box.pack_start (add_remove_footer_box, false, true, 0);

    //create the webview to display page content
    webkitSettings = new WebKit.Settings();
    webkitSettings.set_allow_file_access_from_file_urls (true);
    webkitSettings.set_allow_universal_access_from_file_urls(true); //this gives launchpad build error
    webkitSettings.set_auto_load_images(true);
    aWebView = new WebKit.WebView.with_settings(webkitSettings);
    aWebView.set_zoom_level(BookwormApp.Settings.get_instance().zoom_level);
    webkitSettings.set_enable_javascript(true);
    //This is for setting the font to the system font - Is this required ?
    //webkitSettings.set_default_font_family(aWebView.get_style_context().get_font(StateFlags.NORMAL).get_family ());
    webkitSettings.set_default_font_size (BookwormApp.Bookworm.settings.reading_font_size);
    webkitSettings.set_default_font_family(BookwormApp.Bookworm.settings.reading_font_name);

    //Set up Button for previous page
    Gtk.Image back_button_image = new Gtk.Image.from_icon_name ("go-previous-symbolic", Gtk.IconSize.MENU);
    back_button = new Gtk.Button ();
    back_button.set_image (back_button_image);
    back_button.set_relief (ReliefStyle.NONE);

    //Set up Button for next page
    Gtk.Image forward_button_image = new Gtk.Image.from_icon_name ("go-next-symbolic", Gtk.IconSize.MENU);
    forward_button = new Gtk.Button ();
    forward_button.set_image (forward_button_image);
    forward_button.set_relief (ReliefStyle.NONE);

    //Set up a slider for jumping pages
    pageAdjustment = new Adjustment (0, 1, 100, 1, 0, 0);
    pageSlider = new Gtk.Scale(Gtk.Orientation.HORIZONTAL, pageAdjustment);
    pageSlider.set_digits (0);
		pageSlider.set_valign (Gtk.Align.START);
    pageSlider.set_hexpand(true);

    //Set up contents of the footer
    ActionBar book_reading_footer_box = new ActionBar();
    book_reading_footer_box.pack_start (back_button);
    book_reading_footer_box.pack_start (pageSlider);
    book_reading_footer_box.pack_end (forward_button);
    book_reading_footer_box.set_center_widget(pageSlider);

    //Create the Gtk Box to hold components for reading a selected book
    bookReading_ui_box = new Gtk.Box (Orientation.VERTICAL, 0);
    bookReading_ui_box.set_border_width (0);
    bookReading_ui_box.pack_start (aWebView, true, true, 0);
    bookReading_ui_box.pack_start (book_reading_footer_box, false, true, 0);

    //Add all ui components to the main UI box
    Gtk.Box main_ui_box = new Gtk.Box (Orientation.VERTICAL, 0);
    main_ui_box.set_border_width (0);
    main_ui_box.pack_start(bookLibrary_ui_box, true, true, 0);
    main_ui_box.pack_start(BookwormApp.Info.createBookInfo(), true, true, 0);
    main_ui_box.pack_end(bookReading_ui_box, true, true, 0);
    //main_ui_box.get_style_context().add_class ("box_white");

    //Add action to open a book for clicking on row in library list view
    library_table_treeview.row_activated.connect ((path, column) => {
      Gtk.TreeIter iter;
	    Value bookLocation;
      TreeModel aTreeModel =  library_table_treeview.get_model ();
	    aTreeModel.get_iter (out iter, path);
	    aTreeModel.get_value (iter, 7, out bookLocation);

      BookwormApp.Book aBook  = BookwormApp.Bookworm.libraryViewMap.get((string) bookLocation);
      if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[6] ||
         BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[7])
      {
        BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[7];
        BookwormApp.Library.updateListViewForSelection(aBook);
      }
	    if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[5]){
        BookwormApp.Bookworm.readSelectedBook(aBook);
      }
    });

    //Add action to update tree view when editing is Completed
    title_cell_txt.edited.connect((path, new_text) => {
      Gtk.TreeIter iter;
	    Value bookLocation;
      TreeModel aTreeModel =  library_table_treeview.get_model ();
      Gtk.TreePath aTreePath = new Gtk.TreePath.from_string (path);
	    aTreeModel.get_iter (out iter, aTreePath);
	    aTreeModel.get_value (iter, 7, out bookLocation);
      updateLibraryListViewData((string) bookLocation, new_text, 1);
    });
    author_cell_txt.edited.connect((path, new_text) => {
      Gtk.TreeIter iter;
	    Value bookLocation;
      TreeModel aTreeModel =  library_table_treeview.get_model ();
      Gtk.TreePath aTreePath = new Gtk.TreePath.from_string (path);
	    aTreeModel.get_iter (out iter, aTreePath);
	    aTreeModel.get_value (iter, 7, out bookLocation);
      updateLibraryListViewData((string) bookLocation, new_text, 2);
    });
    tags_cell_txt.edited.connect((path, new_text) => {
      Gtk.TreeIter iter;
	    Value bookLocation;
      TreeModel aTreeModel =  library_table_treeview.get_model ();
      Gtk.TreePath aTreePath = new Gtk.TreePath.from_string (path);
	    aTreeModel.get_iter (out iter, aTreePath);
	    aTreeModel.get_value (iter, 7, out bookLocation);
      updateLibraryListViewData((string) bookLocation, new_text, 5);
    });

    //Add action to open the context menu on right click of tree view
    library_table_treeview.button_press_event.connect ((event) => {
      //capture which mouse button was clicked on the book in the library
      uint mouseButtonClicked;
      event.get_button(out mouseButtonClicked);
      //handle right button click for context menu
      if (event.get_event_type ()  == Gdk.EventType.BUTTON_PRESS  &&  mouseButtonClicked == 3){
        /*TreeIter iter;
        TreeModel model;
  	    Value bookLocation;
  	    TreeSelection selection = library_table_treeview.get_selection();
        selection.get_selected (out model, out iter);
        model.get_value (iter, 0, out bookLocation);
        BookwormApp.Book aBook  = BookwormApp.Bookworm.libraryViewMap.get((string) bookLocation);
        TODO:Set up the right click context
        */
      };
      return false; //return false to propagate the action further i.e. row activation
    });

    //Add action on the forward button for reading
    forward_button.clicked.connect (() => {
      //get object for this ebook and call the next page
      BookwormApp.Book currentBookForForward = new BookwormApp.Book();
      currentBookForForward = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
      debug("Initiating read forward for eBook:"+currentBookForForward.getBookLocation());
      currentBookForForward = BookwormApp.Bookworm.renderPage(currentBookForForward, "FORWARD");
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
      //update book details to libraryView Map
      BookwormApp.Bookworm.libraryViewMap.set(currentBookForReverse.getBookLocation(), currentBookForReverse);
      BookwormApp.Bookworm.locationOfEBookCurrentlyRead = currentBookForReverse.getBookLocation();
    });
    //Add action for moving the pages for the page slider
    pageSlider.change_value.connect ((scroll, new_value) => {
      debug("Page Slider value change Initiated for book at location:"+BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
      BookwormApp.Book currentBookForSlider = new BookwormApp.Book();
      currentBookForSlider = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
      currentBookForSlider.setBookPageNumber(new_value.to_string().to_int()-1);
      //update book details to libraryView Map
      currentBookForSlider = BookwormApp.Bookworm.renderPage(currentBookForSlider, "");
      BookwormApp.Bookworm.libraryViewMap.set(currentBookForSlider.getBookLocation(), currentBookForSlider);
      BookwormApp.Bookworm.locationOfEBookCurrentlyRead = currentBookForSlider.getBookLocation();
      debug("Page Slider value change action completed for book at location:"+BookwormApp.Bookworm.locationOfEBookCurrentlyRead+" and rendering completed for page number:"+currentBookForSlider.getBookPageNumber().to_string());
      return true;
    });
    //Add action for adding a book on the library view
    add_book_button.clicked.connect (() => {
      ArrayList<string> selectedEBooks = BookwormApp.Utils.selectFileChooser(Gtk.FileChooserAction.OPEN, _("Select eBook"), BookwormApp.Bookworm.window, true, "EBOOKS");
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
      //check if the library is in List View mode
      if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[5] ||
         BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[6] ||
         BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[7])
      {
        //check if the mode is already in selection mode
        if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[6] ||
           BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[7])
        {
          //UI is already in selection/selected mode - second click puts the view in normal mode
          BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[5];
          BookwormApp.Library.updateListViewForSelection(null);
        }else{
          //UI is not in selection/selected mode - set the view mode to selection mode
          BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[6];
          BookwormApp.Library.updateListViewForSelection(null);
        }
      }else{
        //check if the mode is already in selection mode
        if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[2] ||
           BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[3])
        {
          //UI is already in selection/selected mode - second click puts the view in normal mode
          BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = settings.library_view_mode;
          BookwormApp.Library.updateGridViewForSelection(null);
        }else{
          //UI is not in selection/selected mode - set the view mode to selection mode
          BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[2];
          BookwormApp.Library.updateGridViewForSelection(null);
        }
      }

    });
    //Add action for removing a selected book on the library view
    remove_book_button.clicked.connect (() => {
      BookwormApp.Bookworm.removeSelectedBooksFromLibrary();
    });
    //handle context menu on the webview reader
    aWebView.context_menu.connect ((context_menu, event, hit_test_result) => {
      context_menu.remove_all();
      Gtk.Action pageActionFullScreenEntry = new Gtk.Action ("FULL_SCREEN_READING_VIEW",
                                              BookwormApp.Constants.TEXT_FOR_PAGE_CONTEXTMENU_FULL_SCREEN_ENTRY,
                                              BookwormApp.Constants.TOOLTIP_TEXT_FOR_PAGE_CONTEXTMENU_FULL_SCREEN_ENTRY,
                                              null);
      Gtk.Action pageActionFullScreenExit = new Gtk.Action ("FULL_SCREEN_READING_VIEW",
                                              BookwormApp.Constants.TEXT_FOR_PAGE_CONTEXTMENU_FULL_SCREEN_EXIT,
                                              BookwormApp.Constants.TOOLTIP_TEXT_FOR_PAGE_CONTEXTMENU_FULL_SCREEN_EXIT,
                                              null);
      Gtk.Action pageActionWordMeaning = new Gtk.Action ("WORD_MEANING",
                                              BookwormApp.Constants.TEXT_FOR_PAGE_CONTEXTMENU_WORD_MEANING,
                                              null,
                                              null);
      pageActionWordMeaning.set_sensitive(false); //TODO: Implement word meaning
      WebKit.ContextMenuItem pageContextMenuItemWordMeaning = new WebKit.ContextMenuItem (pageActionWordMeaning);
      WebKit.ContextMenuItem pageContextMenuItemFullScreenEntry = new WebKit.ContextMenuItem (pageActionFullScreenEntry);
      WebKit.ContextMenuItem pageContextMenuItemFullScreenExit = new WebKit.ContextMenuItem (pageActionFullScreenExit);
      context_menu.append(pageContextMenuItemWordMeaning);
      if(book_reading_footer_box.get_visible()){
        context_menu.append(pageContextMenuItemFullScreenEntry);
      }else{
        context_menu.append(pageContextMenuItemFullScreenExit);
      }

      //Set Context menu items
      pageActionFullScreenEntry.activate.connect (() => {
        book_reading_footer_box.hide();
        BookwormApp.Bookworm.window.fullscreen();
      });
      pageActionFullScreenExit.activate.connect (() => {
        book_reading_footer_box.show();
        BookwormApp.Bookworm.window.unfullscreen();
      });
      return false;
    });
    //capture key press events on the webview reader
    aWebView.key_press_event.connect ((ev) => {
        if (ev.keyval == Gdk.Key.Left) {// Left Key pressed, move page backwards
          //get object for this ebook
          BookwormApp.Book aBookLeftKeyPress = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
          aBookLeftKeyPress = BookwormApp.Bookworm.renderPage(aBookLeftKeyPress, "BACKWARD");
          //update book details to libraryView Map
          BookwormApp.Bookworm.libraryViewMap.set(aBookLeftKeyPress.getBookLocation(), aBookLeftKeyPress);
        }
        if (ev.keyval == Gdk.Key.Right) {// Right key pressed, move page forward
          //get object for this ebook
          BookwormApp.Book aBookRightKeyPress = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
          aBookRightKeyPress = BookwormApp.Bookworm.renderPage(aBookRightKeyPress, "FORWARD");
          //update book details to libraryView Map
          BookwormApp.Bookworm.libraryViewMap.set(aBookRightKeyPress.getBookLocation(), aBookRightKeyPress);
        }
        if (ev.keyval == Gdk.Key.Escape) {// Escape key pressed, remove full screen
          book_reading_footer_box.show();
          BookwormApp.Bookworm.window.unfullscreen();
        }
        if (ev.keyval == Gdk.Key.F11) {// F11 key pressed, enter or remove full screen
          book_reading_footer_box.hide();
          BookwormApp.Bookworm.window.fullscreen();
        }
        return false;
    });

    //capture the url clicked on the webview and action the navigation type clicks
    aWebView.decide_policy.connect ((decision, type) => {
     if(type == WebKit.PolicyDecisionType.RESPONSE){
       debug("Signal captured for Policy type WebKit.PolicyDecisionType.RESPONSE");
     }
     if(type == WebKit.PolicyDecisionType.NEW_WINDOW_ACTION){
       debug("Signal captured for Policy type WebKit.PolicyDecisionType.NEW_WINDOW_ACTION");
     }
     if(type == WebKit.PolicyDecisionType.NAVIGATION_ACTION){
       debug("Signal captured for Policy type WebKit.PolicyDecisionType.NAVIGATION_ACTION");
       WebKit.NavigationPolicyDecision aNavDecision = (WebKit.NavigationPolicyDecision)decision;
       WebKit.NavigationAction aNavAction = aNavDecision.get_navigation_action();
       WebKit.URIRequest aURIReq = aNavAction.get_request ();
       debug("URL Captured:"+aURIReq.get_uri().strip());
       BookwormApp.Book aBook = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
       string url_clicked_on_webview = BookwormApp.Utils.decodeHTMLChars(aURIReq.get_uri().strip());
       debug("Cleaned URL Captured:"+url_clicked_on_webview);
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

  public static bool updateLibraryListViewData(string bookLocation, string new_text, int column){
    debug("Started to update metadata in List View for book:"+bookLocation);
    //iterate over the list store
    Gtk.TreeIter iter;
    string bookLocationforCurrentRow;
    library_table_liststore.get_iter_first (out iter);
    library_table_liststore.get (iter, 7, out bookLocationforCurrentRow);
    if(bookLocation == bookLocationforCurrentRow) {
      library_table_liststore.set (iter, column, new_text);
      BookwormApp.Book aBook  = BookwormApp.Bookworm.libraryViewMap.get((string) bookLocation);
      if(column == 1){
        aBook.setBookTitle(new_text);
      }
      if(column == 2){
        aBook.setBookAuthor(new_text);
      }
      if(column == 5){
        aBook.setBookTags(new_text);
      }
      aBook.setWasBookOpened(true);
      BookwormApp.Bookworm.libraryViewMap.set(aBook.getBookLocation(), aBook);
      return true; //break out of the iterations
    }
    while(library_table_liststore.iter_next (ref iter)){
      library_table_liststore.get (iter, 7, out bookLocationforCurrentRow);
      if(bookLocation == bookLocationforCurrentRow) {
        library_table_liststore.set (iter, column, new_text);
        BookwormApp.Book aBook  = BookwormApp.Bookworm.libraryViewMap.get((string) bookLocation);
        if(column == 1){
          aBook.setBookTitle(new_text);
        }
        if(column == 2){
          aBook.setBookAuthor(new_text);
        }
        if(column == 5){
          aBook.setBookTags(new_text);
        }
        aBook.setWasBookOpened(true);
        BookwormApp.Bookworm.libraryViewMap.set(aBook.getBookLocation(), aBook);
        return true; //break out of the iterations
      }
    }
    return true;
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

      ArrayList<string> selectedEBooks = BookwormApp.Utils.selectFileChooser(Gtk.FileChooserAction.OPEN, _("Select eBook"), BookwormApp.Bookworm.window, true, "EBOOKS");
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

  public static void showInfoBar(BookwormApp.Book aBook, MessageType aMessageType){
    StringBuilder message = new StringBuilder("");
    message.append(aBook.getParsingIssue())
             .append(aBook.getBookLocation());
    BookwormApp.AppWindow.infobarLabel.set_text(message.str);
    BookwormApp.AppWindow.infobar.set_message_type (aMessageType);
    BookwormApp.AppWindow.infobar.show();
  }

  //Handle action for close of the InfoBar
	public static void on_info_bar_closed(){
      BookwormApp.AppWindow.infobar.hide();
	}
}
