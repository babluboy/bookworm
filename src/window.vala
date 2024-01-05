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
    public static Gtk.ActionBar book_reading_footer_box;
    public static Gtk.Box bookReading_ui_box;
    public static Gtk.Button forward_button;
    public static Gtk.GestureSwipe gesture_swipe;
    public static Gtk.Button back_button;
    public static Gtk.ProgressBar bookAdditionBar;
    public static Adjustment pageAdjustment;
    public static Scale pageSlider;
    public static BookwormApp.Settings settings;
    public static bool isWebViewRequestCompleted = true;
    public static Gtk.Button remove_book_button;
    public static Gtk.Button page_button_prev;
    public static Gtk.Button page_button_next;
    public static int noOfBooksSelected = 0;


    public static Gtk.Box createBoookwormUI () {
        info ("[START] [FUNCTION:createBoookwormUI]");
        settings = BookwormApp.Settings.get_instance ();

        //Create a grid to display the books cover images in library
        library_grid = new Gtk.FlowBox ();
        library_grid.set_border_width (BookwormApp.Constants.SPACING_WIDGETS);
        library_grid.column_spacing = BookwormApp.Constants.SPACING_WIDGETS;
        library_grid.row_spacing = BookwormApp.Constants.SPACING_WIDGETS;
        library_grid.set_valign (Gtk.Align.START);

        library_grid_scroll = new ScrolledWindow (null, null);
        library_grid_scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        library_grid_scroll.add (library_grid);

        //Create a treeview and Liststore to display the list of books in the library
        library_table_liststore = new Gtk.ListStore (8,
            typeof (Gdk.Pixbuf), typeof (string), typeof (string), typeof (string),
            typeof (Gdk.Pixbuf), typeof (string), typeof (string), typeof (string));
        library_table_treeview = new Gtk.TreeView ();
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

        //Create a box to hold the grid view and list view - only one is visible at a time
        Gtk.Box library_view_box = new Gtk.Box (Orientation.VERTICAL, 0);
        library_view_box.set_border_width (0);
        library_view_box.pack_start (library_grid_scroll, true, true, 0);
        library_view_box.pack_start (library_list_scroll, true, true, 0);
        //Set up Button for selecting books
        Gtk.Button select_book_button = new Gtk.Button ();
        select_book_button.set_image (BookwormApp.Bookworm.select_book_image);
        select_book_button.set_relief (ReliefStyle.NONE);
        select_book_button.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_SELECT_BOOK);

        //Set up Button for adding books
        Gtk.Button add_book_button = new Gtk.Button ();
        add_book_button.set_image (BookwormApp.Bookworm.add_book_image);
        add_book_button.set_relief (ReliefStyle.NONE);
        add_book_button.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_ADD_BOOK);

        //Set up Button for removing books
        remove_book_button = new Gtk.Button ();
        remove_book_button.set_image (BookwormApp.Bookworm.remove_book_image);
        remove_book_button.set_relief (ReliefStyle.NONE);
        //set the button as disabled - it will be enabled only if books are selected
        remove_book_button.set_sensitive (false);
        remove_book_button.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_REMOVE_BOOK_UNSELECTED);

        //Set up buttons for paginating the library
        Gtk.Box library_page_switcher_box = new Gtk.Box (Orientation.HORIZONTAL, 0);
        library_page_switcher_box.set_border_width (0);

        page_button_prev = new Gtk.Button ();
        page_button_prev.set_image (BookwormApp.Bookworm.back_page_image);
        page_button_prev.set_relief (ReliefStyle.NONE);
        page_button_prev.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_PREV_PAGE);
        library_page_switcher_box.pack_start (page_button_prev);
        page_button_prev.set_sensitive (false); //disable the prev button on first time load

        page_button_next = new Gtk.Button ();
        page_button_next.set_image (BookwormApp.Bookworm.forward_page_image);
        page_button_next.set_relief (ReliefStyle.NONE);
        page_button_next.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_NEXT_PAGE);
        library_page_switcher_box.pack_start (page_button_next);

        //Set up the progress bar for addition of books to library
        bookAdditionBar = new Gtk.ProgressBar ();
        bookAdditionBar.set_valign (Gtk.Align.CENTER);
        bookAdditionBar.set_show_text (true);

        //Create a footer and add widgets for select/add/remove books
        ActionBar add_remove_footer_box = new ActionBar ();
        add_remove_footer_box.pack_start (select_book_button);
        add_remove_footer_box.pack_start (add_book_button);
        add_remove_footer_box.pack_start (remove_book_button);
        add_remove_footer_box.pack_start (bookAdditionBar);
        add_remove_footer_box.pack_end (library_page_switcher_box);

        //Create a MessageBar to show status messages
        infobar = new Gtk.InfoBar ();
        infobarLabel = new Gtk.Label ("");
        Gtk.Container infobarContent = infobar.get_content_area ();
        infobar.set_message_type (MessageType.INFO);
        infobarContent.add (infobarLabel);
        infobar.set_show_close_button (true);
        infobar.response.connect (on_info_bar_closed);
        infobar.hide ();

        //Create the UI for library view and add all components to ui box for library view
        bookLibrary_ui_box = new Gtk.Box (Orientation.VERTICAL, 0);
        bookLibrary_ui_box.set_border_width (0);
        bookLibrary_ui_box.pack_start (library_view_box, true, true, 0);
        bookLibrary_ui_box.pack_start (add_remove_footer_box, false, true, 0);

        //create the webview to display page content
        webkitSettings = new WebKit.Settings ();
        webkitSettings.set_allow_file_access_from_file_urls (true);
        webkitSettings.set_allow_universal_access_from_file_urls (true); //this gives launchpad build error for Yaketty
        webkitSettings.set_auto_load_images (true);
        aWebView = new WebKit.WebView.with_settings (webkitSettings);
        aWebView.set_zoom_level (BookwormApp.Settings.get_instance ().zoom_level);
        aWebView.load_changed.connect((loadEvent) => {
            switch (loadEvent) {
                case WebKit.LoadEvent.STARTED:
                    break;
                case WebKit.LoadEvent.REDIRECTED:
                    break;
                case WebKit.LoadEvent.COMMITTED:
                    break;
                case WebKit.LoadEvent.FINISHED:
                    aWebView.run_javascript(BookwormApp.Bookworm.onLoadJavaScript.str, null);
                    break;
            }
        });
        webkitSettings.set_enable_javascript (true);
        //This is for setting the font to the system font - Is this required ?
        //webkitSettings.set_default_font_family (aWebView.get_style_context ().get_font (StateFlags.NORMAL).get_family ());
        webkitSettings.set_default_font_size (BookwormApp.Bookworm.settings.reading_font_size);
        webkitSettings.set_default_font_family (BookwormApp.Bookworm.settings.reading_font_name);
        gesture_swipe = new Gtk.GestureSwipe(aWebView);
        gesture_swipe.set_propagation_phase(Gtk.PropagationPhase.CAPTURE);

        //Set up Button for previous page
        back_button = new Gtk.Button ();
        back_button.set_image (BookwormApp.Bookworm.back_button_image);
        back_button.set_relief (ReliefStyle.NONE);

        //Set up Button for next page
        forward_button = new Gtk.Button ();
        forward_button.set_image (BookwormApp.Bookworm.forward_button_image);
        forward_button.set_relief (ReliefStyle.NONE);

        //Set up a slider for jumping pages
        pageAdjustment = new Adjustment (0, 1, 100, 1, 0, 0);
        pageSlider = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, pageAdjustment);
        pageSlider.set_digits (0);
        pageSlider.set_valign (Gtk.Align.START);
        pageSlider.set_value_pos (Gtk.PositionType.RIGHT);
        pageSlider.set_hexpand (true);

        //Set up contents of the footer
        book_reading_footer_box = new ActionBar ();
        book_reading_footer_box.pack_start (back_button);
        book_reading_footer_box.pack_start (pageSlider);
        book_reading_footer_box.pack_end (forward_button);

        //Create the Gtk Box to hold components for reading a selected book
        bookReading_ui_box = new Gtk.Box (Orientation.VERTICAL, 0);
        bookReading_ui_box.set_border_width (0);
        bookReading_ui_box.pack_start (aWebView, true, true, 0);
        bookReading_ui_box.pack_start (book_reading_footer_box, false, true, 0);

        //Add all ui components to the main UI box
        Gtk.Box main_ui_box = new Gtk.Box (Orientation.VERTICAL, 0);
        main_ui_box.set_border_width (0);
        main_ui_box.pack_start (infobar, false, true, 0);
        main_ui_box.pack_start (bookLibrary_ui_box, true, true, 0);
        main_ui_box.pack_start (BookwormApp.Info.createBookInfo (), true, true, 0);
        main_ui_box.pack_end (bookReading_ui_box, true, true, 0);

        //Add action to open a book for clicking on row in library list view
        library_table_treeview.row_activated.connect ((path, column) => {
            Gtk.TreeIter iter;
            Value bookLocation;
            TreeModel aTreeModel = library_table_treeview.get_model ();
            aTreeModel.get_iter (out iter, path);
            aTreeModel.get_value (iter, 7, out bookLocation);
            BookwormApp.Book aBook = BookwormApp.Bookworm.libraryViewMap.get ((string) bookLocation);
            if (BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[6] ||
                BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[7])
            {
                BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[7];
                BookwormApp.Library.updateListViewForSelection (aBook);
            }
            if (BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[5]) {
                BookwormApp.Bookworm.readSelectedBook (aBook);
            }
        });
        //Add action to update tree view when editing is Completed
        title_cell_txt.edited.connect ((path, new_text) => {
            updateLibraryListViewData (path, new_text, 1);
        });
        author_cell_txt.edited.connect ((path, new_text) => {
            updateLibraryListViewData (path, new_text, 2);
        });
        tags_cell_txt.edited.connect ((path, new_text) => {
            updateLibraryListViewData (path, new_text, 5);
        });
        //Add action to open the context menu on right click of tree view
        library_table_treeview.button_press_event.connect ((event) => {
            //capture which mouse button was clicked on the book in the library
            uint mouseButtonClicked;
            event.get_button (out mouseButtonClicked);
            //handle right button click for context menu
            if (event.get_event_type () == Gdk.EventType.BUTTON_PRESS && mouseButtonClicked == 3) {
                /*TreeIter iter;
                TreeModel model;
                Value bookLocation;
                TreeSelection selection = library_table_treeview.get_selection ();
                selection.get_selected (out model, out iter);
                model.get_value (iter, 0, out bookLocation);
                BookwormApp.Book aBook = BookwormApp.Bookworm.libraryViewMap.get ((string) bookLocation);
                TODO: Set up the right click context
                */
            };
            return false; //return false to propagate the action further i.e. row activation
        });
        // Add action to go to next or previous page in reponse to a finger
        // swipe gesture from right to left to or left to right respectively
        gesture_swipe.swipe.connect((x, y) => {
          // Avoid triggering nagivation actions on mostly vertical swipes that
          // should scroll up or down the page rather then flip it.
          // The x and y-values here are relatively arbitrary but seems to feel
          // right in testing.
          if (y.abs() > 800 || x.abs() < 800) {
            return;
          }

          // x == 0 on tap, so we ignore that
          if (x > 0) {
            handleBookNavigation("PREV");
          } else if (x < 0) {
            handleBookNavigation("NEXT");
          }
        });
        //Add action on the forward button for reading
        forward_button.clicked.connect (() => {
            handleBookNavigation ("NEXT");
        });
        //Add action on the backward button for reading
        back_button.clicked.connect (() => {
            handleBookNavigation ("PREV");
        });
        //Add action for moving the pages for the page slider
        pageSlider.change_value.connect ((scroll, new_value) => {
            debug ("Page Slider value change [" + new_value.to_string () +
                "] Initiated for book at location:" + BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
            BookwormApp.Book currentBookForSlider = new BookwormApp.Book ();
            currentBookForSlider = BookwormApp.Bookworm.libraryViewMap.get (BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
            if ((int.parse (new_value.to_string ())-1) > (currentBookForSlider.getBookContentList ().size)) {
                //this is for the scenario where the slider crosses the max value
                currentBookForSlider.setBookPageNumber (currentBookForSlider.getBookContentList ().size-1);
            } else {
                currentBookForSlider.setBookPageNumber (int.parse (new_value.to_string ())-1);
            }
            //update book details to libraryView Map
            currentBookForSlider = BookwormApp.contentHandler.renderPage (currentBookForSlider, "");
            BookwormApp.Bookworm.libraryViewMap.set (currentBookForSlider.getBookLocation (), currentBookForSlider);
            BookwormApp.Bookworm.locationOfEBookCurrentlyRead = currentBookForSlider.getBookLocation ();
            debug ("Page Slider value change action completed for book at location:" +
                BookwormApp.Bookworm.locationOfEBookCurrentlyRead +
                " and rendering completed for page number:" + currentBookForSlider.getBookPageNumber ().to_string ());
            return true;
        });
        //Add action for adding book (s) on the library view
        add_book_button.clicked.connect (() => {
            ArrayList<string> selectedEBooks = BookwormApp.Utils.selectFileChooser (
                Gtk.FileChooserAction.OPEN, _("Select eBook"), BookwormApp.Bookworm.window, true, "EBOOKS");
            BookwormApp.Bookworm.pathsOfBooksToBeAdded = new string[selectedEBooks.size];
            int countOfBooksToBeAdded = 0;
            foreach (string pathToSelectedBook in selectedEBooks) {
                BookwormApp.Bookworm.pathsOfBooksToBeAdded[countOfBooksToBeAdded] = pathToSelectedBook;
                countOfBooksToBeAdded++;
            }
            //Display the progress bar
            BookwormApp.AppWindow.bookAdditionBar.show ();
            BookwormApp.Bookworm.isBookBeingAddedToLibrary = true;
            BookwormApp.Library.addBooksToLibrary ();
        });
        //Add action for putting library in select view
        select_book_button.clicked.connect (() => {
            //initialize the counter to check how many books are selected
            noOfBooksSelected = 0;
            //check if the library is in List View mode
            if (BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[5] ||
                BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[6] ||
                BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[7])
            {
                //check if the mode is already in selection mode
                if (BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[6] ||
                    BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[7])
                {
                    //UI is already in selection/selected mode - second click puts the view in normal mode
                    BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[5];
                    BookwormApp.Library.updateListViewForSelection (null);
                } else {
                    //UI is not in selection/selected mode - set the view mode to selection mode
                    BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[6];
                    BookwormApp.Library.updateListViewForSelection (null);
                }
            } else {
                //check if the mode is already in selection mode
                if (BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[2] ||
                    BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[3])
                {
                    //UI is already in selection/selected mode - second click puts the view in normal mode
                    BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = settings.library_view_mode;
                    BookwormApp.Library.updateGridViewForSelection (null);
                } else {
                    //UI is not in selection/selected mode - set the view mode to selection mode
                    BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[2];
                    BookwormApp.Library.updateGridViewForSelection (null);
                }
            }
        });
        //Add action for removing a selected book on the library view
        remove_book_button.clicked.connect (() => {
            BookwormApp.Library.removeSelectedBooksFromLibrary ();
        });
        //handle mouse click on webview (reading mode)
        aWebView.button_press_event.connect ((event) => {
            if (!settings.is_leaf_over_page_by_edge_enabled) {
                return false;
            }
            int width;
            int height;
            //capture the current window size
            BookwormApp.Bookworm.window.get_size (out width, out height);
            //capture which mouse button was clicked on the book in the library
            uint mouseButtonClicked;
            event.get_button (out mouseButtonClicked);
            //handle left button click for page navigation if the click is near the left and right margins
            if (event.get_event_type () == Gdk.EventType.BUTTON_PRESS && mouseButtonClicked == 1) {
                //check if mouse is clicked near the right margin 10% of page width and go to previous page
                if(event.x < ((BookwormApp.Constants.PERCENTAGE_WIDTH_FOR_PAGE_NAVIGATION_ON_CLICK/100) * width)){
                    handleBookNavigation ("PREV");
                }
                if(event.x > (width - ((BookwormApp.Constants.PERCENTAGE_WIDTH_FOR_PAGE_NAVIGATION_ON_CLICK/100) * width))){
                    handleBookNavigation ("NEXT");
                }
            };
            return false; //return false to propagate the action further
        });
        //handle context menu on the webview reader
        aWebView.context_menu.connect ((context_menu, event, hit_test_result) => {
            context_menu.remove_all ();
            SimpleAction pageActionFullScreenEntry = new SimpleAction ("FULL_SCREEN_READING_VIEW", null);
            SimpleAction pageActionFullScreenExit = new SimpleAction ("FULL_SCREEN_READING_VIEW", null);
            SimpleAction pageActionWordMeaning = new SimpleAction ("WORD_MEANING", null);
            SimpleAction pageActionAnnotateSelection = new SimpleAction ("ANNOTATE_SELECTION", null);
            WebKit.ContextMenuItem pageContextMenuItemWordMeaning = new WebKit.ContextMenuItem.from_gaction (
                pageActionWordMeaning, BookwormApp.Constants.TEXT_FOR_PAGE_CONTEXTMENU_WORD_MEANING, null);
            WebKit.ContextMenuItem pageContextMenuItemFullScreenEntry = new WebKit.ContextMenuItem.from_gaction (
                pageActionFullScreenEntry, BookwormApp.Constants.TEXT_FOR_PAGE_CONTEXTMENU_FULL_SCREEN_ENTRY, null);
            WebKit.ContextMenuItem pageContextMenuItemFullScreenExit = new WebKit.ContextMenuItem.from_gaction (
                pageActionFullScreenExit, BookwormApp.Constants.TEXT_FOR_PAGE_CONTEXTMENU_FULL_SCREEN_EXIT, null);
            WebKit.ContextMenuItem pageContextMenuItemAnnotateSelection = new WebKit.ContextMenuItem.from_gaction (
                pageActionAnnotateSelection, BookwormApp.Constants.TEXT_FOR_PAGE_CONTEXTMENU_ANNOTATE_SELECTION, null);
            context_menu.append (pageContextMenuItemWordMeaning);
            context_menu.append (pageContextMenuItemAnnotateSelection);
            if (!settings.is_fullscreen) {
                context_menu.append (pageContextMenuItemFullScreenEntry);
            } else {
                context_menu.append (pageContextMenuItemFullScreenExit);
            }
            //Set Context menu items
            pageActionWordMeaning.activate.connect (() => {
                string selected_text = BookwormApp.Utils.setWebViewTitle ("document.title = getSelectionText ()");
                if (selected_text != null && selected_text.length > 0) {
					//Save the page scroll position of the book being read
                    BookwormApp.Book aBook = BookwormApp.Bookworm.libraryViewMap
                        .get (BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
                    aBook.setBookScrollPos (BookwormApp.contentHandler.getScrollPos ());

                    BookwormApp.Info.populateDictionaryResults (selected_text);
                }
            });
            pageActionAnnotateSelection.activate.connect (() => {
                string selected_text = BookwormApp.Utils.setWebViewTitle ("document.title = getSelectionText ()");
                if (selected_text != null && selected_text.length > 0) {
                    BookwormApp.AppDialog.createAnnotationDialog (selected_text);
                }
            });
            pageActionFullScreenEntry.activate.connect (() => {
                book_reading_footer_box.hide ();
                BookwormApp.Bookworm.window.fullscreen ();
            });
            pageActionFullScreenExit.activate.connect (() => {
                book_reading_footer_box.show ();
                BookwormApp.Bookworm.window.unfullscreen ();
            });
            return false;
        });
        //capture the url clicked on the webview and action the navigation type clicks
        aWebView.decide_policy.connect ((decision, type) => {
            if (type == WebKit.PolicyDecisionType.RESPONSE) {
                debug ("Signal captured for Policy type WebKit.PolicyDecisionType.RESPONSE");
                isWebViewRequestCompleted = true;
            }
            if (type == WebKit.PolicyDecisionType.NEW_WINDOW_ACTION) {
                debug ("Signal captured for Policy type WebKit.PolicyDecisionType.NEW_WINDOW_ACTION");
                isWebViewRequestCompleted = true;
            }
            if (type == WebKit.PolicyDecisionType.NAVIGATION_ACTION && isWebViewRequestCompleted) {
                debug ("Signal captured for Policy type WebKit.PolicyDecisionType.NAVIGATION_ACTION");
                //set the webview request flag to false to prevent re-trigger of this function
                //the webview request flag will be set to true when the response is received
                isWebViewRequestCompleted = false;
                WebKit.NavigationPolicyDecision aNavDecision = (WebKit.NavigationPolicyDecision)decision;
                WebKit.NavigationAction aNavAction = aNavDecision.get_navigation_action ();
                WebKit.URIRequest aURIReq = aNavAction.get_request ();
                string url_clicked_on_webview = BookwormApp.Utils.decodeHTMLChars (aURIReq.get_uri ().strip ());
                url_clicked_on_webview = GLib.Uri.unescape_string (url_clicked_on_webview);
                debug ("URL Captured:" + url_clicked_on_webview);
                //Handle external links (not file://) by opening the default browser i.e. http://, ftp://
                if (url_clicked_on_webview.index_of ("file://") == -1) {
                    BookwormApp.Utils.execute_sync_command ("xdg-open " + url_clicked_on_webview);
                    decision.ignore ();
                    return true;
                }
                //Handle Bookworm type links i.e. Annotation Overlay
                debug ("Window Title:" + BookwormApp.AppWindow.aWebView.get_title ());
                if (BookwormApp.AppWindow.aWebView.get_title () != null &&
                    BookwormApp.AppWindow.aWebView.get_title ().length > 1 &&
                    BookwormApp.AppWindow.aWebView.get_title ().index_of ("annotation:") != -1)
                {
                    //Open the annotation dialog
                    BookwormApp.AppDialog.createAnnotationDialog (
                        BookwormApp.AppWindow.aWebView.get_title ().replace ("annotation:", ""));
                    isWebViewRequestCompleted = true;
                }
                //Handle file:/// type links to other content of the book i.e. Table of Contents
                string anchor = "";
                if (url_clicked_on_webview.index_of ("#") != -1) {
                    string[] url_splitted_by_hashtag = url_clicked_on_webview.split("#", 2);
                    url_clicked_on_webview = url_splitted_by_hashtag[0];
                    anchor = url_splitted_by_hashtag[1];
                }
                url_clicked_on_webview = File.new_for_path (url_clicked_on_webview).get_basename ();
                int contentLocationPosition = 0;
                BookwormApp.Book aBook = BookwormApp.Bookworm.libraryViewMap
                    .get (BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
                foreach (string aBookContent in aBook.getBookContentList ()) {
                    if (BookwormApp.Utils.decodeHTMLChars (aBookContent).index_of (url_clicked_on_webview) != -1) {
                        debug ("Matched Link Clicked to book content:" +
                            BookwormApp.Utils.decodeHTMLChars (aBookContent));
                        aBook.setBookPageNumber (contentLocationPosition);
                        //update book details to libraryView Map
                        BookwormApp.Bookworm.libraryViewMap.set (aBook.getBookLocation (), aBook);
                        if (anchor.len() > 0) { // anchor - id in link after # symbol
                            BookwormApp.Bookworm.isPageScrollRequired = true;
                            aBook.setAnchor(anchor);
                        }
                        aBook = BookwormApp.contentHandler.renderPage (aBook, "");
                        //Set the mode back to Reading mode
                        BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[1];
                        BookwormApp.Bookworm.toggleUIState ();
                        debug ("URL is initiated from Bookworm Contents, Book page number set at:" +
                            aBook.getBookPageNumber ().to_string ());
                        break;
                    }
                    contentLocationPosition++;
                }
            }
            isWebViewRequestCompleted = true;
            return true;
        });
        //Add action for paginating the library
        page_button_next.clicked.connect (() => {
            handleLibraryPageButtons ("NEXT_PAGE", true);
        });
        page_button_prev.clicked.connect (() => {
            handleLibraryPageButtons ("PREV_PAGE", true);
        });
        info ("[END] [FUNCTION:createBoookwormUI]");
        return main_ui_box;
    }

    public static void handleBookNavigation (string action){
        //action for NEXT page
        if(action == "NEXT") {
            //get object for this ebook and call the next page
            BookwormApp.Book currentBookForForward = new BookwormApp.Book ();
            currentBookForForward = BookwormApp.Bookworm.libraryViewMap.get (BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
            debug ("Initiating read forward for eBook:" + currentBookForForward.getBookLocation ());
            currentBookForForward = BookwormApp.contentHandler.renderPage (currentBookForForward, "FORWARD");
            //update book details to libraryView Map
            BookwormApp.Bookworm.libraryViewMap.set (currentBookForForward.getBookLocation (), currentBookForForward);
            BookwormApp.Bookworm.locationOfEBookCurrentlyRead = currentBookForForward.getBookLocation ();
        }
        //action for PREV page
        if(action == "PREV") {
            //get object for this ebook and call the next page
            BookwormApp.Book currentBookForReverse = new BookwormApp.Book ();
            currentBookForReverse = BookwormApp.Bookworm.libraryViewMap.get (BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
            debug ("Initiating read previous for eBook:" + currentBookForReverse.getBookLocation ());
            currentBookForReverse = BookwormApp.contentHandler.renderPage (currentBookForReverse, "BACKWARD");
            //update book details to libraryView Map
            BookwormApp.Bookworm.libraryViewMap.set (currentBookForReverse.getBookLocation (), currentBookForReverse);
            BookwormApp.Bookworm.locationOfEBookCurrentlyRead = currentBookForReverse.getBookLocation ();
        }
    }

    public static void handleLibraryPageButtons (string mode, bool isPaginateRequired) {
        if (mode == "NEXT_PAGE" && isPaginateRequired) {
            //activate the previous page button if it is disabled
            if (!page_button_prev.get_sensitive ()) {
                page_button_prev.set_sensitive (true);
            }
            //move the counter to the next position
            BookwormApp.Bookworm.current_page_counter = BookwormApp.Bookworm.current_page_counter + 1;
            BookwormApp.Library.paginateLibrary ("", "PAGINATED_SEARCH");
            //disable the forward button if the last modification date returned -1 for this page position
            if (BookwormApp.Bookworm.paginationlist.contains ("-1")) {
                page_button_next.set_sensitive (false);
            }
        }
        if (mode == "PREV_PAGE" && isPaginateRequired) {
            if (BookwormApp.Bookworm.current_page_counter > 0) {
                //activate the next page button if it is disabled
                if (!page_button_next.get_sensitive ()) {
                    page_button_next.set_sensitive (true);
                }
                //remove -1 from the paginated list if present of last modification dates to allow the forward button to work
                if (BookwormApp.Bookworm.paginationlist.contains ("-1")) {
                    BookwormApp.Bookworm.paginationlist.remove ("-1");
                }
                BookwormApp.Bookworm.current_page_counter = BookwormApp.Bookworm.current_page_counter - 1;
                BookwormApp.Library.paginateLibrary ("", "PAGINATED_SEARCH");
            } else {
                //disable the prev button as the counter is on the first page
                page_button_prev.set_sensitive (false);
            }
        }
        if (!isPaginateRequired) { //set the button status without doing pagination
            if (BookwormApp.Bookworm.current_page_counter < 1) {
                page_button_prev.set_sensitive (false);
            }
            if (BookwormApp.Bookworm.paginationlist.contains ("-1")) {
                page_button_next.set_sensitive (false);
            }
        }
    }

    public static bool updateLibraryListViewData (string path, string new_text, int column) {
        info ("[START] [FUNCTION:updateLibraryListViewData] updating metadata in List View on row:" +
            path + " for change:" + new_text + " on column:" + column.to_string ());
        //Determine the book whose meta data is being updated
        Gtk.TreeIter sortedIter;
        Value bookLocation;
        TreeModel aTreeModel = library_table_treeview.get_model ();
        Gtk.TreePath aTreePath = new Gtk.TreePath.from_string (path);
        aTreeModel.get_iter (out sortedIter, aTreePath);
        aTreeModel.get_value (sortedIter, 7, out bookLocation);
        //iterate over the list store
        Gtk.TreeIter iter;
        string bookLocationforCurrentRow;
        bool iterExists = true;
        iterExists = library_table_liststore.get_iter_first (out iter);
        while (iterExists) {
            library_table_liststore.get (iter, 7, out bookLocationforCurrentRow);
            if ((string)bookLocation == bookLocationforCurrentRow) {
                library_table_liststore.set (iter, column, new_text);
                BookwormApp.Book aBook = BookwormApp.Bookworm.libraryViewMap.get ((string) bookLocation);
                if (column == 1) {
                    aBook.setBookTitle (new_text);
                }
                if (column == 2) {
                    aBook.setBookAuthor (new_text);
                }
                if (column == 5) {
                    aBook.setBookTags (new_text);
                }
                aBook.setWasBookOpened (true);
                BookwormApp.Bookworm.libraryViewMap.set (aBook.getBookLocation (), aBook);
                debug ("Completed updating metadata in List View for book:" + (string) bookLocation);
                return true; //break out of the iterations
            }
            iterExists = library_table_liststore.iter_next (ref iter);
        }
        info ("[END] [FUNCTION:updateLibraryListViewData]");
        return true;
    }

    public static Granite.Widgets.Welcome createWelcomeScreen () {
        info ("[START] [FUNCTION:createWelcomeScreen]");
        //Create a welcome screen for view of library with no books
        BookwormApp.Bookworm.welcomeWidget = new Granite.Widgets.Welcome (
            BookwormApp.Constants.TEXT_FOR_WELCOME_MESSAGE_TITLE,
            BookwormApp.Constants.TEXT_FOR_WELCOME_MESSAGE_SUBTITLE);
        Gtk.Image? openFolderImage = new Gtk.Image.from_icon_name ("document-open", Gtk.IconSize.DIALOG);
        BookwormApp.Bookworm.welcomeWidget.append_with_image (
            openFolderImage, "Open", BookwormApp.Constants.TEXT_FOR_WELCOME_OPENDIR_MESSAGE);
        //Add action for adding a book on the library view
        BookwormApp.Bookworm.welcomeWidget.activated.connect (() => {
            ArrayList<string> selectedEBooks = BookwormApp.Utils.selectFileChooser (
                Gtk.FileChooserAction.OPEN, _("Select eBook"), BookwormApp.Bookworm.window, true, "EBOOKS");
            //If ebooks were selected, remove the welcome widget from main window and show the library view
            if (selectedEBooks.size > 0) {
                BookwormApp.Bookworm.window.remove (BookwormApp.Bookworm.welcomeWidget);
                BookwormApp.Bookworm.window.add (BookwormApp.Bookworm.bookWormUIBox);
                BookwormApp.Bookworm.bookWormUIBox.show_all ();
                BookwormApp.Bookworm.toggleUIState ();
                BookwormApp.Bookworm.pathsOfBooksToBeAdded = new string[selectedEBooks.size];
                int countOfBooksToBeAdded = 0;
                foreach (string pathToSelectedBook in selectedEBooks) {
                    BookwormApp.Bookworm.pathsOfBooksToBeAdded[countOfBooksToBeAdded] = pathToSelectedBook;
                    countOfBooksToBeAdded++;
                }
                //Display the progress bar
                BookwormApp.AppWindow.bookAdditionBar.show ();
                BookwormApp.Bookworm.isBookBeingAddedToLibrary = true;
                BookwormApp.Library.addBooksToLibrary ();
            }
        });
        info ("[END] [FUNCTION:createWelcomeScreen] ");
        return BookwormApp.Bookworm.welcomeWidget;
    }

    public static void showInfoBar (BookwormApp.Book aBook, MessageType aMessageType) {
        debug ("[START] [FUNCTION:showInfoBar] ");
        StringBuilder message = new StringBuilder ("");
        message.append (aBook.getParsingIssue ()).append (aBook.getBookLocation ());
        BookwormApp.AppWindow.infobarLabel.set_text (message.str);
        BookwormApp.AppWindow.infobar.set_message_type (aMessageType);
        BookwormApp.AppWindow.infobar.show ();
        debug ("[END] [FUNCTION:showInfoBar] with message:" + message.str);
    }

    //Handle action for close of the InfoBar
    public static void on_info_bar_closed () {
        BookwormApp.AppWindow.infobar.hide ();
    }

    public static bool handleWindowStateEvents (Gdk.EventWindowState ev) {
        if (ev.type == Gdk.EventType.WINDOW_STATE) {
            if ((ev.window.get_state () & Gdk.WindowState.FULLSCREEN) == 0) {
                settings.is_fullscreen = false;
            } else {
                settings.is_fullscreen = true;
            }
        }
        return false;
    }

    public static void controlDeletionButton (bool selectionState) {
        if (selectionState) {
            //Enable the Deletion Button as a book is selected for potential removal
            noOfBooksSelected++;
            remove_book_button.set_sensitive (true);
            remove_book_button.
                set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_REMOVE_BOOK);
        } else {
            //Check and Disable the Deletion Button if no books are selected after this de-selection
            noOfBooksSelected--;
            if (noOfBooksSelected < 1) {
                remove_book_button.set_sensitive (false);
                remove_book_button.set_tooltip_markup (
                    BookwormApp.Constants.TOOLTIP_TEXT_FOR_REMOVE_BOOK_UNSELECTED);
            }
        }
    }


}
