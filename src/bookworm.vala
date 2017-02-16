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

using Gtk;
using Gee;
using Granite.Widgets;

public const string GETTEXT_PACKAGE = "bookworm";

namespace BookwormApp {

	public class Bookworm:Granite.Application {
		public Gtk.Window window;
		public int exitCodeForCommand = 0;
		public static string bookworm_config_path = GLib.Environment.get_user_config_dir ()+"/bookworm";
		public static bool command_line_option_version = false;
		public static bool command_line_option_alert = false;
		public static bool command_line_option_debug = false;
		[CCode (array_length = false, array_null_terminated = true)]
		public static string command_line_option_monitor = "";
		public new OptionEntry[] options;
		public static Bookworm application;
		public Gtk.SearchEntry headerSearchBar;
		public StringBuilder spawn_async_with_pipes_output = new StringBuilder("");

		public WebKit.WebView aWebView;
		public ePubReader aReader;
		public Gtk.HeaderBar headerbar;
		public Gtk.Box bookSelection_ui_box;
		public Gtk.Box bookReading_ui_box;
		public ScrolledWindow library_scroll;
		public Gtk.Grid library_grid;
		//public Gtk.Grid library_grid_selection;
		//public Gtk.Grid library_grid_selected;
		public Gdk.Pixbuf bookSelectionPix;
		public Gdk.Pixbuf bookSelectedPix;
		public Gtk.Image bookSelectionImage;
		public Gdk.Pixbuf aBookCover;
		//public Gtk.Image aCoverImage;

		public string BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[0];
		public static Gee.HashMap<string, BookwormApp.Book> libraryViewMap = new Gee.HashMap<string, BookwormApp.Book>();
		public string locationOfEBookCurrentlyRead = "";
		public int countBooksAddedIntoLibraryRow = 0;
		public Widget lastBookUpdatedIntoLibraryGrid = null;
		public Gee.HashMap<string,Gtk.EventBox> libraryViewEventBoxWidgets = new Gee.HashMap<string,Gtk.EventBox>();
		public BookwormApp.Book aBook;
		public Sqlite.Database bookwormDB;

		construct {
			application_id = "org.bookworm";
			flags |= ApplicationFlags.HANDLES_COMMAND_LINE;

			program_name = "Bookworm";
			app_years = "2017";

			build_version = Constants.bookworm_version;
			app_icon = "bookworm";
			main_url = "https://launchpad.net/bookworm";
			bug_url = "https://bugs.launchpad.net/bookworm";
			help_url = "https://answers.launchpad.net/bookworm";
			translate_url = "https://translations.launchpad.net/bookworm";

			about_documenters = { null };
			about_artists = { "Siddhartha Das <bablu.boy@gmail.com>" };
			about_authors = { "Siddhartha Das <bablu.boy@gmail.com>" };
			about_comments = _("An eBook Reader");
			about_translators = _("Launchpad Translators");
			about_license_type = Gtk.License.GPL_3_0;

			options = new OptionEntry[4];
			options[0] = { "version", 0, 0, OptionArg.NONE, ref command_line_option_version, _("Display version number"), null };
			options[3] = { "debug", 0, 0, OptionArg.NONE, ref command_line_option_debug, _("Run Bookworm in debug mode"), null };
			add_main_option_entries (options);
		}

		public Bookworm() {
			Intl.setlocale(LocaleCategory.MESSAGES, "");
			Intl.textdomain(GETTEXT_PACKAGE);
			Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "utf-8");
			Intl.bindtextdomain(GETTEXT_PACKAGE, "./locale");
			debug ("Completed setting Internalization...");
		}

		public static int main (string[] args) {
			Log.set_handler ("bookworm", GLib.LogLevelFlags.LEVEL_DEBUG, GLib.Log.default_handler);
			if("--debug" in args){
				Environment.set_variable ("G_MESSAGES_DEBUG", "all", true);
				debug ("Bookworm Application running in debug mode - all debug messages will be displayed");
			}
			application = new Bookworm();

			//Workaround to get Granite's --about & Gtk's --help working together
			if ("--help" in args || "-h" in args || "--monitor" in args || "--alert" in args || "--version" in args) {
				return application.processCommandLine (args);
			} else {
				Gtk.init (ref args);
				return application.run(args);
			}
		}

		public override int command_line (ApplicationCommandLine command_line) {
			activate();
			return 0;
		}

		private int processCommandLine (string[] args) {
			try {
				var opt_context = new OptionContext ("- bookworm");
				opt_context.set_help_enabled (true);
				opt_context.add_main_entries (options, null);
				unowned string[] tmpArgs = args;
				opt_context.parse (ref tmpArgs);
			} catch (OptionError e) {
				info ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
				info ("error: %s\n", e.message);
				return 0;
			}
			//check and run nutty based on command line option
			if(command_line_option_debug){
				debug ("Bookworm running in debug mode...");
			}
			if(command_line_option_version){
				print("\nbookworm version "+Constants.bookworm_version+" \n");
				return 0;
			}else{
				activate();
				return 0;
			}
		}

		public override void activate() {
			debug("Starting to activate Gtk Window for Bookworm...");
			window = new Gtk.Window ();
			add_window (window);
			//set window attributes
			window.set_default_size(1000, 600);
			window.set_border_width (Constants.SPACING_WIDGETS);
			window.set_position (Gtk.WindowPosition.CENTER);
			window.window_position = Gtk.WindowPosition.CENTER;
			//load state information from file
			loadBookwormState();
			//add window components
			create_headerbar(window);
			window.add(createBoookwormUI());
			window.show_all();
			toggleUIState();

			//Exit Application Event
			window.destroy.connect (() => {
				//save state information to file
				saveBookwormState();
			});
			debug("Completed loading Gtk Window for Bookworm...");
		}

		private void create_headerbar(Gtk.Window window) {
			debug("Starting creation of header bar..");
			headerbar = new Gtk.HeaderBar();
			headerbar.set_title(program_name);
			headerbar.subtitle = Constants.TEXT_FOR_SUBTITLE_HEADERBAR;
			headerbar.set_show_close_button(true);
			headerbar.spacing = Constants.SPACING_WIDGETS;
			window.set_titlebar (headerbar);
			window.maximize();
			//add menu items to header bar - content list button
			Gtk.Image library_view_button_image = new Gtk.Image ();
			library_view_button_image.set_from_file (Constants.LIBRARY_VIEW_IMAGE_LOCATION);
			Gtk.Button library_view_button = new Gtk.Button ();
			library_view_button.set_image (library_view_button_image);

			Gtk.Image content_list_button_image = new Gtk.Image ();
			content_list_button_image.set_from_file (Constants.CONTENTS_VIEW_IMAGE_LOCATION);
			Gtk.Button content_list_button = new Gtk.Button ();
			content_list_button.set_image (content_list_button_image);

			headerbar.pack_start(library_view_button);
			headerbar.pack_start(content_list_button);

			//add menu items to header bar - Menu
			headerbar.pack_end(createBookwormMenu(new Gtk.Menu ()));

			//Add a search entry to the header
			headerSearchBar = new Gtk.SearchEntry();
			headerSearchBar.set_text(Constants.TEXT_FOR_SEARCH_HEADERBAR);
			headerbar.pack_end(headerSearchBar);
			headerSearchBar.set_sensitive(false);
			// Set actions for HeaderBar search
			headerSearchBar.search_changed.connect (() => {

			});
			library_view_button.clicked.connect (() => {
				//Update header to remove title of book being read
				headerbar.subtitle = "";
				//set UI in library view mode
				BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[0];
				updateLibraryViewForSelectionMode(null);
				toggleUIState();
			});
			content_list_button.clicked.connect (() => {
				//get object for this ebook
				aBook = libraryViewMap.get(locationOfEBookCurrentlyRead);
				aBook = BookwormApp.ePubReader.renderPage(aWebView, aBook, "TABLE_OF_CONTENTS");
			});
			debug("Completed loading HeaderBar sucessfully...");
		}

		public AppMenu createBookwormMenu (Gtk.Menu menu) {
			debug("Starting creation of Bookworm Menu...");
			Granite.Widgets.AppMenu app_menu;
			//Add sub menu items
			Gtk.MenuItem menuItemPrefferences = new Gtk.MenuItem.with_label(Constants.TEXT_FOR_HEADERBAR_MENU_PREFS);
			menu.add (menuItemPrefferences);
			Gtk.MenuItem menuItemExportToFile = new Gtk.MenuItem.with_label(Constants.TEXT_FOR_HEADERBAR_MENU_EXPORT);
			menu.add (menuItemExportToFile);
			app_menu = new Granite.Widgets.AppMenu.with_app(this, menu);

			//Add actions for menu items
			menuItemPrefferences.activate.connect(() => {

			});
			menuItemExportToFile.activate.connect(() => {

			});
			//Add About option to menu
			app_menu.show_about.connect (show_about);
			debug("Completed creation of Bookworm Menu sucessfully...");
			return app_menu;
		}

		public Gtk.Box createBoookwormUI() {
			debug("Starting to create main window components...");

			//Create a box to display the book library
			library_grid = new Gtk.Grid ();
			library_grid.set_column_spacing (BookwormApp.Constants.SPACING_WIDGETS);
			library_grid.set_row_spacing (BookwormApp.Constants.SPACING_WIDGETS);

			library_scroll = new ScrolledWindow (null, null);
			library_scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
			library_scroll.add (library_grid);

			//Set up Button for adding books
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

			//Create a footer to select/add/remove books
			Gtk.Box add_remove_footer_box = new Gtk.Box (Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_BUTTONS);
			//Set up contents of the add/remove books footer label
			add_remove_footer_box.pack_start (select_book_button, false, true, 0);
			add_remove_footer_box.pack_start (add_book_button, false, true, 0);
			add_remove_footer_box.pack_start (remove_book_button, false, true, 0);

			//Create the UI for library view
			bookSelection_ui_box = new Gtk.Box (Orientation.VERTICAL, 0);
			//add all components to ui box for library view
			bookSelection_ui_box.pack_start (library_scroll, true, true, 0);
      bookSelection_ui_box.pack_start (add_remove_footer_box, false, true, 0);


			//create the webview to display page content
			WebKit.Settings webkitSettings = new WebKit.Settings();
	    webkitSettings.set_allow_file_access_from_file_urls (true);
	    webkitSettings.set_default_font_family("helvetica");
			//webkitSettings.set_allow_universal_access_from_file_urls(true);
	    webkitSettings.set_auto_load_images(true);
	    aWebView = new WebKit.WebView.with_settings(webkitSettings);
			//aWebView.set_zoom_level (6.0); // use this for page zooming

			//Set up Button for previous page
			Gtk.Image back_button_image = new Gtk.Image ();
			back_button_image.set_from_file (BookwormApp.Constants.PREV_PAGE_ICON_IMAGE_LOCATION);
			Gtk.Button back_button = new Gtk.Button ();
			back_button.set_image (back_button_image);

			//Set up Button for next page
			Gtk.Image forward_button_image = new Gtk.Image ();
			forward_button_image.set_from_file (BookwormApp.Constants.NEXT_PAGE_ICON_IMAGE_LOCATION);
			Gtk.Button forward_button = new Gtk.Button ();
			forward_button.set_image (forward_button_image);

			//Set up contents of the footer
			Gtk.Box book_reading_footer_box = new Gtk.Box (Orientation.HORIZONTAL, 0);
			Gtk.Label pageNumberLabel = new Label("");
			book_reading_footer_box.pack_start (back_button, false, true, 0);
			book_reading_footer_box.pack_start (pageNumberLabel, true, true, 0);
			book_reading_footer_box.pack_end (forward_button, false, true, 0);

			//Create the Gtk Box to hold components for reading a selected book
			bookReading_ui_box = new Gtk.Box (Orientation.VERTICAL, 0);
			bookReading_ui_box.pack_start (aWebView, true, true, 0);
      bookReading_ui_box.pack_start (book_reading_footer_box, false, true, 0);

			//Add all ui components to the main UI box
			Gtk.Box main_ui_box = new Gtk.Box (Orientation.VERTICAL, 0);
			main_ui_box.pack_start(bookSelection_ui_box, true, true, 0);
			main_ui_box.pack_end(bookReading_ui_box, true, true, 0);

			//Add all UI action listeners

			//Add action on the forward button for reading
			forward_button.clicked.connect (() => {
				//get object for this ebook and call the next page
				aBook = libraryViewMap.get(locationOfEBookCurrentlyRead);
				debug("Initiating read forward for eBook:"+aBook.to_string());
				aBook = BookwormApp.ePubReader.renderPage(aWebView, aBook, "FORWARD");
				//update book details to libraryView Map
				libraryViewMap.set(aBook.getBookLocation(), aBook);
				locationOfEBookCurrentlyRead = aBook.getBookLocation();
				//set the focus to the webview to capture keypress events
				aWebView.grab_focus();
			});
			//Add action on the backward button for reading
			back_button.clicked.connect (() => {
				//get object for this ebook and call the next page
				aBook = libraryViewMap.get(locationOfEBookCurrentlyRead);
				debug("Initiating read previous for eBook:"+aBook.to_string());
				aBook = BookwormApp.ePubReader.renderPage(aWebView, aBook, "BACKWARD");
				//update book details to libraryView Map
				libraryViewMap.set(aBook.getBookLocation(), aBook);
				locationOfEBookCurrentlyRead = aBook.getBookLocation();
				//set the focus to the webview to capture keypress events
				aWebView.grab_focus();
			});
			//Add action for adding a book on the library view
			add_book_button.clicked.connect (() => {
				string pathToSelectedBook = selectBookFileChooser();
				aBook = new BookwormApp.Book();
				aBook.setBookLocation(pathToSelectedBook);
				addBookToLibrary(aBook);
			});
			//Add action for putting library in select view
			select_book_button.clicked.connect (() => {
				//check if the mode is already in selection mode
				if(BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[2] || BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[3]){
					//UI is already in selection/selected mode - second click puts the view in normal mode
					BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[0];
					updateLibraryViewForSelectionMode(null);
				}else{
					//UI is not in selection/selected mode - set the view mode to selection mode
					BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[2];
					updateLibraryViewForSelectionMode(null);
				}
			});

			//Add action for removing a selected book on the library view
			remove_book_button.clicked.connect (() => {
				removeSelectedBooksFromLibrary();
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
						aBook = libraryViewMap.get(locationOfEBookCurrentlyRead);
						aBook = BookwormApp.ePubReader.renderPage(aWebView, aBook, "BACKWARD");
					}
			    if (ev.keyval == Gdk.Key.Right) {// Right key pressed, move page forward
						//get object for this ebook
						aBook = libraryViewMap.get(locationOfEBookCurrentlyRead);
						aBook = BookwormApp.ePubReader.renderPage(aWebView, aBook, "FORWARD");
					}
			    return false;
			});
			//capture the url clicked on the webview
			aWebView.decide_policy.connect (() => {
				string url_clicked_on_webview = aWebView.get_uri().replace("%20"," ");
				if(url_clicked_on_webview != null && url_clicked_on_webview.length > 1){
					aBook = libraryViewMap.get(locationOfEBookCurrentlyRead);
					if(aBook.getBookContentList().contains(url_clicked_on_webview.replace(BookwormApp.Constants.PREFIX_FOR_FILE_URL, ""))){
						aBook.setBookPageNumber(aBook.getBookContentList().index_of(url_clicked_on_webview.replace(BookwormApp.Constants.PREFIX_FOR_FILE_URL, "")));
						debug("Using Table of Contents Navigation, Book page number set at"+aBook.getBookPageNumber().to_string());
					}
				}
				return true;
			});

			//ensure all required set up is present
			ensureRequiredSetUp();
			//update the grid based on books present in database library
			updateLibraryViewFromDB();

			debug("Completed creation of main window components...");
			return main_ui_box;
		}

		public void ensureRequiredSetUp(){
			//check and create required directory structure
	    BookwormApp.Utils.fileOperations("CREATEDIR", BookwormApp.Constants.EPUB_EXTRACTION_LOCATION, "", "");
			BookwormApp.Utils.fileOperations("CREATEDIR", bookworm_config_path, "", "");
			BookwormApp.Utils.fileOperations("CREATEDIR", bookworm_config_path+"/covers/", "", "");
			//check if the database exists otherwise create it
			int ec = Sqlite.Database.open_v2 (bookworm_config_path+"/bookworm.db", out bookwormDB, Sqlite.OPEN_READWRITE | Sqlite.OPEN_CREATE);
			if (ec != Sqlite.OK) {
				warning ("Can't open database: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
			}
			//create main table if it does not exist
			string errmsg;
			string create_table_query = "CREATE TABLE IF NOT EXISTS BOOK_LIBRARY_TABLE ("
                               + "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                               + "BOOK_LOCATION TEXT NOT NULL DEFAULT '', "
															 + "BOOK_TITLE TEXT NOT NULL DEFAULT '', "
                               + "BOOK_AUTHOR TEXT NOT NULL DEFAULT '', "
                               + "BOOK_COVER_IMAGE_LOCATION TEXT NOT NULL DEFAULT '', "
															 + "IS_BOOK_COVER_IMAGE_PRESENT TEXT NOT NULL DEFAULT '', "
                               + "BOOK_PUBLISH_DATE TEXT NOT NULL DEFAULT '', "
															 + "BOOK_TOC_DATA TEXT NOT NULL DEFAULT '', "
															 + "BOOK_TOTAL_NUMBER_OF_PAGES TEXT NOT NULL DEFAULT '', "
															 + "BOOK_LAST_READ_PAGE_NUMBER TEXT NOT NULL DEFAULT '', "
                               + "creation_date INTEGER,"
                               + "modification_date INTEGER)";
				ec = bookwormDB.exec (create_table_query, null, out errmsg);
			 	if (ec != Sqlite.OK) {
			 		warning ("Error: %s\n", errmsg);
			 	}
				//set default cover image of book and selection images
				aBookCover = new Gdk.Pixbuf.from_file_at_scale(BookwormApp.Constants.DEFAULT_COVER_IMAGE_LOCATION, 150, 200, false);
		}

		public void removeSelectedBooksFromLibrary(){
			ArrayList<string> listOfBooksToBeRemoved = new ArrayList<string> ();
			//loop through the Library View Hashmap
			foreach (var book in libraryViewMap.values){
				//check if the book selection flag to true and remove book
				if(((BookwormApp.Book)book).getIsBookSelected()){
					//hold the books to be deleted in a list
					listOfBooksToBeRemoved.add(((BookwormApp.Book)book).getBookLocation());
					Gtk.EventBox lEventBox = ((BookwormApp.Book)book).getEventBox();
					//destroy the EventBox widget - this removes the book from the library grid
					lEventBox.destroy();
				}
			}
			//loop through the removed books and remove them from the Library View Hashmap and Database
			foreach (string bookLocation in listOfBooksToBeRemoved) {
				removeBookFromDB(libraryViewMap.get(bookLocation));
				libraryViewMap.unset(bookLocation);
			}
			window.show_all();
			toggleUIState();
		}

		public string selectBookFileChooser(){
			string eBookLocation = "";
			//create a hashmap to hold details for the book
			Gee.HashMap<string,string> bookDetailsMap = new Gee.HashMap<string,string>();
	    //choose eBook using a File chooser dialog
			Gtk.FileChooserDialog aFileChooserDialog = BookwormApp.Utils.new_file_chooser_dialog (Gtk.FileChooserAction.OPEN, "Select eBook", window, false);
	    aFileChooserDialog.show_all ();
	    if (aFileChooserDialog.run () == Gtk.ResponseType.ACCEPT) {
	      eBookLocation = aFileChooserDialog.get_filename();
	      BookwormApp.Utils.last_file_chooser_path = aFileChooserDialog.get_current_folder();
	      debug("Last visited folder for FileChooserDialog set as:"+BookwormApp.Utils.last_file_chooser_path);
	      aFileChooserDialog.destroy();
	    }else{
	      aFileChooserDialog.destroy();
	    }
			return eBookLocation;
		}

		public void addBookToLibrary(owned BookwormApp.Book aBook){
			//check if book already exists in the library
			if(libraryViewMap.has_key(aBook.getBookLocation())){
				//TO-DO: Set a message for the user
				//TO-DO: Bring the book to the first position in the library view
			}else{
				debug("Initiated process to add eBook to library from path:"+aBook.getBookLocation());
				//check if the selected eBook exists
				string eBookLocation = aBook.getBookLocation();
				File eBookFile = File.new_for_path (eBookLocation);
				if(eBookFile.query_exists() && eBookFile.query_file_type(0) != FileType.DIRECTORY){
					string extractionLocation = BookwormApp.ePubReader.extractEBook(eBookLocation);
					aBook.setBookExtractionLocation(extractionLocation);
					//determine location of eBook cover image
					aBook = BookwormApp.ePubReader.getBookCoverImageLocation(aBook, bookworm_config_path);
					//determine title of eBook
					aBook = BookwormApp.ePubReader.getBookTitle(aBook, bookworm_config_path);
					//add book details to libraryView Map
					libraryViewMap.set(eBookLocation, aBook);
					//set the name of the book being currently read
					locationOfEBookCurrentlyRead = eBookLocation;
					//add eBook cover image to library view
					updateLibraryView(aBook);
					//insert book details to database
					addBookToDataBase(aBook);
					debug ("Completed adding book to ebook library. Number of books in library:"+libraryViewMap.size.to_string());
				}else{
					debug("No ebook found for adding to library");
				}
			}
		}

		public void updateLibraryView(owned BookwormApp.Book aBook){
			debug("Updating Library for cover:"+aBook.getBookCoverLocation());
			Gtk.EventBox aEventBox = new Gtk.EventBox();
			aEventBox.set_name(aBook.getBookLocation());
			Gtk.Overlay aOverlayImage = new Gtk.Overlay();
			Gtk.Image aCoverImage = new Gtk.Image.from_pixbuf(aBookCover);
			string bookCoverLocation;

			if(!aBook.getIsBookCoverImagePresent()){
				bookCoverLocation = aBook.getBookCoverLocation();
				aOverlayImage.add(aCoverImage);//use the default Book Cover Image
				Gtk.Label overlayTextLabel = new Gtk.Label("<b>"+aBook.getBookTitle()+"</b>");
				overlayTextLabel.set_use_markup (true);
				overlayTextLabel.set_line_wrap (true);
				aOverlayImage.add_overlay(overlayTextLabel);
				aEventBox.add(aOverlayImage);
			}else{
				bookCoverLocation = aBook.getBookCoverLocation();
				aBookCover = new Gdk.Pixbuf.from_file_at_scale(bookCoverLocation, 150, 200, false);
				aCoverImage = new Gtk.Image.from_pixbuf(aBookCover);
				aOverlayImage.add(aCoverImage);
				aEventBox.add(aOverlayImage);
			}
			//check if there are no books in the library view
			if(lastBookUpdatedIntoLibraryGrid == null){
				library_grid.attach (aEventBox, 0, 0, 1, 1);
				countBooksAddedIntoLibraryRow++;
			}else{
				//check if the top row has the maximum number of books already
				if(countBooksAddedIntoLibraryRow < BookwormApp.Constants.MAX_BOOK_COVER_PER_ROW){
					library_grid.attach_next_to (aEventBox, lastBookUpdatedIntoLibraryGrid, PositionType.LEFT, 1, 1);
					countBooksAddedIntoLibraryRow++;
				}else{
					//max books on a row has been reached add the book on a new top row
					library_grid.attach_next_to (aEventBox, null, PositionType.TOP, 1, 1);
					countBooksAddedIntoLibraryRow = 0;
				}
			}
			//set gtk objects into Book objects
			aBook.setCoverImage (aCoverImage);
			aBook.setEventBox(aEventBox);
			aBook.setOverlayImage(aOverlayImage);

			lastBookUpdatedIntoLibraryGrid = aEventBox;
			//set the view mode
			BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[0];
			window.show_all();
			toggleUIState();

			//add listener for book objects based on mode
			aEventBox.button_press_event.connect (() => {
				if(BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[0]){
					aBook  = libraryViewMap.get(aEventBox.get_name());
					debug("Initiated process for reading eBook:"+aBook.getBookLocation());
					readSelectedBook(aBook);
				}
				if(BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[2] || BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[3]){
					BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[3];
					aBook  = libraryViewMap.get(aEventBox.get_name());
					updateLibraryViewForSelectionMode(aBook);
				}
				return true;
			});
			//add book details to libraryView Map
			libraryViewMap.set(aBook.getBookLocation(), aBook);
			//update eventbox widet into EventBook HashMap
			libraryViewEventBoxWidgets.set(aBook.getBookLocation(), aEventBox);
		}

		public void updateLibraryViewForSelectionMode(owned BookwormApp.Book? lBook){
			if(BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[0]){
				//loop over HashMap of Book Objects and overlay selection image
				foreach (var book in libraryViewMap.values){
					//set the book selection flag to false
					((BookwormApp.Book)book).setIsBookSelected(false);
					Gtk.EventBox lEventBox = ((BookwormApp.Book)book).getEventBox();
					Gtk.Overlay lOverlayImage = ((BookwormApp.Book)book).getOverlayImage();
					lEventBox.remove(lOverlayImage);
					lOverlayImage.remove(((BookwormApp.Book)book).getCoverImage());
					lOverlayImage.destroy();

					if(!((BookwormApp.Book)book).getIsBookCoverImagePresent()){
						Gdk.Pixbuf aBookCover = new Gdk.Pixbuf.from_file_at_scale(BookwormApp.Constants.DEFAULT_COVER_IMAGE_LOCATION, 150, 200, false);
						Gtk.Image aCoverImage = new Gtk.Image.from_pixbuf(aBookCover);
						lOverlayImage.add(aCoverImage);//use the default Book Cover Image
						Gtk.Label overlayTextLabel = new Gtk.Label("<b>"+((BookwormApp.Book)book).getBookTitle()+"</b>");
						overlayTextLabel.set_use_markup (true);
						overlayTextLabel.set_line_wrap (true);
						lOverlayImage.add_overlay(overlayTextLabel);
						lEventBox.add(lOverlayImage);
					}else{
						Gdk.Pixbuf aBookCover = new Gdk.Pixbuf.from_file_at_scale(((BookwormApp.Book)book).getBookCoverLocation(), 150, 200, false);
						Gtk.Image aCoverImage = new Gtk.Image.from_pixbuf(aBookCover);
						lOverlayImage.add(aCoverImage);
						lEventBox.add(lOverlayImage);
					}
					//update overlay image into book object
					((BookwormApp.Book)book).setOverlayImage(lOverlayImage);
					//update event box into book object
					((BookwormApp.Book)book).setEventBox(lEventBox);
				}
			}
			if(BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[2]){
				//loop over HashMap of Book Objects and overlay selection image
				foreach (var book in libraryViewMap.values){
					Gtk.EventBox lEventBox = ((BookwormApp.Book)book).getEventBox();
					Gtk.Overlay lOverlayImage = ((BookwormApp.Book)book).getOverlayImage();

					bookSelectionPix = new Gdk.Pixbuf.from_file(BookwormApp.Constants.SELECTION_OPTION_IMAGE_LOCATION);
					bookSelectionImage = new Gtk.Image.from_pixbuf(bookSelectionPix);
					bookSelectionImage.set_halign(Align.START);
					bookSelectionImage.set_valign(Align.START);
					lOverlayImage.add_overlay(bookSelectionImage);

					lEventBox.add(lOverlayImage);
					//update overlay image into book object
					((BookwormApp.Book)book).setOverlayImage(lOverlayImage);
					//update event box into book object
					((BookwormApp.Book)book).setEventBox(lEventBox);
				}
			}
			if(BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[3]){
				Gtk.EventBox lEventBox = lBook.getEventBox();
				Gtk.Overlay lOverlayImage = lBook.getOverlayImage();
				lEventBox.remove(lOverlayImage);
				lOverlayImage.remove(lBook.getCoverImage());
				lOverlayImage.destroy();

				if(!lBook.getIsBookCoverImagePresent()){
					Gdk.Pixbuf aBookCover = new Gdk.Pixbuf.from_file_at_scale(BookwormApp.Constants.DEFAULT_COVER_IMAGE_LOCATION, 150, 200, false);
					Gtk.Image aCoverImage = new Gtk.Image.from_pixbuf(aBookCover);
					lOverlayImage.add(aCoverImage);//use the default Book Cover Image
					Gtk.Label overlayTextLabel = new Gtk.Label("<b>"+lBook.getBookTitle()+"</b>");
					overlayTextLabel.set_use_markup (true);
					overlayTextLabel.set_line_wrap (true);
					lOverlayImage.add_overlay(overlayTextLabel);

					//add selection image to overlay
					Gdk.Pixbuf bookSelectionPix = new Gdk.Pixbuf.from_file(BookwormApp.Constants.SELECTION_OPTION_IMAGE_LOCATION);
					Gtk.Image bookSelectionImage = new Gtk.Image.from_pixbuf(bookSelectionPix);
					bookSelectionImage.set_halign(Align.START);
					bookSelectionImage.set_valign(Align.START);
					lOverlayImage.add_overlay(bookSelectionImage);

					if(!lBook.getIsBookSelected()){
						//add selected image to overlay if it is not present
						Gdk.Pixbuf bookSelectedPix = new Gdk.Pixbuf.from_file(BookwormApp.Constants.SELECTION_CHECKED_IMAGE_LOCATION);
						Gtk.Image bookSelectedImage = new Gtk.Image.from_pixbuf(bookSelectedPix);
						bookSelectedImage.set_halign(Align.START);
						bookSelectedImage.set_valign(Align.START);
						lOverlayImage.add_overlay(bookSelectedImage);
						lBook.setIsBookSelected(true);
					}else{
						lBook.setIsBookSelected(false);
					}
				}else{
					Gdk.Pixbuf aBookCover = new Gdk.Pixbuf.from_file_at_scale(lBook.getBookCoverLocation(), 150, 200, false);
					Gtk.Image aCoverImage = new Gtk.Image.from_pixbuf(aBookCover);
					lOverlayImage.add(aCoverImage);

					//add selection image to overlay
					Gdk.Pixbuf bookSelectionPix = new Gdk.Pixbuf.from_file(BookwormApp.Constants.SELECTION_OPTION_IMAGE_LOCATION);
					Gtk.Image bookSelectionImage = new Gtk.Image.from_pixbuf(bookSelectionPix);
					bookSelectionImage.set_halign(Align.START);
					bookSelectionImage.set_valign(Align.START);
					lOverlayImage.add_overlay(bookSelectionImage);

					if(!lBook.getIsBookSelected()){
						Gdk.Pixbuf bookSelectedPix = new Gdk.Pixbuf.from_file(BookwormApp.Constants.SELECTION_CHECKED_IMAGE_LOCATION);
						Gtk.Image bookSelectedImage = new Gtk.Image.from_pixbuf(bookSelectedPix);
						bookSelectedImage.set_halign(Align.START);
						bookSelectedImage.set_valign(Align.START);
						lOverlayImage.add_overlay(bookSelectedImage);
						lBook.setIsBookSelected(true);
					}else{
						lBook.setIsBookSelected(false);
					}
				}
				lEventBox.add(lOverlayImage);

				//update overlay image into book object
				lBook.setOverlayImage(lOverlayImage);
				//update event box into book object
				lBook.setEventBox(lEventBox);
				//update the book into the Library view HashMap
				libraryViewMap.set(lBook.getBookLocation(),lBook);
			}
			window.show_all();
			toggleUIState();
		}

		public void readSelectedBook(owned BookwormApp.Book aBook){
			//create temp location for extraction of eBook
			string eBookLocation = aBook.getBookLocation();
			string extractionLocation = BookwormApp.Constants.EPUB_EXTRACTION_LOCATION + File.new_for_path(eBookLocation).get_basename();
			aBook.setBookExtractionLocation(extractionLocation);
			//check and create directory for extracting contents of ebook
			BookwormApp.Utils.fileOperations("CREATEDIR", extractionLocation, "", "");
			//unzip eBook contents into temp location
			BookwormApp.Utils.execute_sync_command("unzip -o \"" + eBookLocation + "\" -d \""+ extractionLocation +"\"");
			debug("eBook extracted into folder:"+extractionLocation);

			//change the application view to Book Reading mode
			BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[1];
			toggleUIState();
			//Update header title
			headerbar.subtitle = aBook.getBookTitle();
			//check if the book content is available
			if(aBook.getBookContentList().size > 0){
				// no need of parsing ebook for content location
			}else{
				//get list of content pages in book
				aBook = BookwormApp.ePubReader.getListOfPagesInBook(aBook);
			}
			aBook = BookwormApp.ePubReader.renderPage(aWebView, aBook, "");
			//update book details to libraryView Map
			libraryViewMap.set(aBook.getBookLocation(), aBook);
			locationOfEBookCurrentlyRead = aBook.getBookLocation();
		}

		public void addBookToDataBase(BookwormApp.Book aBook){
			Sqlite.Statement stmt;
			string insert_data_to_database = "INSERT INTO BOOK_LIBRARY_TABLE(
																															 BOOK_LOCATION,
																															 BOOK_TITLE,
																															 BOOK_COVER_IMAGE_LOCATION,
																															 IS_BOOK_COVER_IMAGE_PRESENT,
																															 creation_date,
																															 modification_date) "
										                + "VALUES (?,?,?,?, CAST(strftime('%s', 'now') AS INT), CAST(strftime('%s', 'now') AS INT))";
			 int ec = bookwormDB.prepare_v2 (insert_data_to_database, insert_data_to_database.length, out stmt);
			 if (ec != Sqlite.OK) {
				 debug("Executed Query:"+stmt.sql());
				 stderr.printf ("Error: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
			 }
			 stmt.bind_text (1, aBook.getBookLocation());
			 stmt.bind_text (2, aBook.getBookTitle());
			 stmt.bind_text (3, aBook.getBookCoverLocation());
			 stmt.bind_text (4, aBook.getIsBookCoverImagePresent().to_string());

			 stmt.step ();
			 stmt.reset ();
			 debug("Added details to Database for book:"+aBook.getBookLocation());
		}

		public void removeBookFromDB(BookwormApp.Book aBook){
			Sqlite.Statement stmt;
			string delete_book_from_database = "DELETE FROM BOOK_LIBRARY_TABLE WHERE BOOK_LOCATION = ?";
			int ec = bookwormDB.prepare_v2 (delete_book_from_database, delete_book_from_database.length, out stmt);
			if (ec != Sqlite.OK) {
				debug("Executed Query:"+stmt.sql());
				stderr.printf ("Error: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
			}
			stmt.bind_text (1, aBook.getBookLocation());
			stmt.step ();
			stmt.reset ();
			debug("Removed this book from Database:"+aBook.getBookLocation());
		}

		public void updateLibraryViewFromDB(){
			Sqlite.Statement stmt;
			string fetchLibraryQuery = "SELECT id,
																				 BOOK_LOCATION,
																				 BOOK_TITLE,
																				 BOOK_COVER_IMAGE_LOCATION,
																				 IS_BOOK_COVER_IMAGE_PRESENT,
																				 BOOK_PUBLISH_DATE,
																				 creation_date,
																				 modification_date
																  FROM BOOK_LIBRARY_TABLE ORDER BY id";
			int ec = bookwormDB.prepare_v2 (fetchLibraryQuery, -1, out stmt);
			assert (ec == Sqlite.OK);
			while (stmt.step () == Sqlite.ROW) {
				aBook = new BookwormApp.Book();
				aBook.setBookId(stmt.column_int(0));
				aBook.setBookLocation(stmt.column_text (1));
				aBook.setBookTitle(stmt.column_text (2));
				aBook.setBookCoverLocation(stmt.column_text (3));
				aBook.setIsBookCoverImagePresent((stmt.column_text (4) == "true") ? true:false);
				aBook.setBookPublishDate(stmt.column_text (5));
				aBook.setBookCreationDate(stmt.column_text (6));
				aBook.setBookLastModificationDate(stmt.column_text (7));
				debug("Book details fetched from DB:
									id="+stmt.column_int(0).to_string()+
									",BOOK_LOCATION="+stmt.column_text (1)+
									",BOOK_TITLE="+stmt.column_text (2)+
									",BOOK_COVER_IMAGE_LOCATION="+stmt.column_text (3)+
									",IS_BOOK_COVER_IMAGE_PRESENT="+stmt.column_text (4)+
									",BOOK_PUBLISH_DATE="+stmt.column_text (5)+
									",creation_date="+stmt.column_text (6)+
									",modification_date="+stmt.column_text (7)
							);
				updateLibraryView(aBook);
				//add book details to libraryView Map
				libraryViewMap.set(aBook.getBookLocation(), aBook);
			}
			stmt.reset ();
		}

		public void toggleUIState(){
			if(BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[0] ||
				 BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[2] ||
				 BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[3]
				){
				//Only show the UI for selecting a book
				bookReading_ui_box.set_visible(false);
				bookSelection_ui_box.set_visible(true);
			}
			if(BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[1]){
				//Only show the UI for reading a book
				bookReading_ui_box.set_visible(true);
				bookSelection_ui_box.set_visible(false);
			}
		}

		public void saveBookwormState(){
			debug("Starting to save Bookworm state...");

		}

		public void loadBookwormState(){
			debug("Started loading Bookworm state...");

		}
	}
}
