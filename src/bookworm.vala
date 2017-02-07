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
		public string BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[0];
		public Gtk.Box bookSelection_ui_box;
		public Gtk.Box bookReading_ui_box;
		public Gtk.Grid library_grid;
		public static Gee.HashMap<string, BookwormApp.Book> libraryViewMap = new Gee.HashMap<string, BookwormApp.Book>();
		public string locationOfEBookCurrentlyRead = "";
		public int countBooksAddedIntoLibraryRow = 0;
		public Widget lastBookUpdatedIntoLibraryGrid = null;
		public Gee.HashMap<string,Gtk.EventBox> libraryViewEventBoxWidgets = new Gee.HashMap<string,Gtk.EventBox>();
		public BookwormApp.Book aBook;

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
				//set UI for library view
				BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[0];
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
			Gtk.Box main_ui_box = new Gtk.Box (Orientation.VERTICAL, 0);

			//Create the UI for selecting a book
			bookSelection_ui_box = new Gtk.Box (Orientation.VERTICAL, 0);
			//Create a box to display the book library
			library_grid = new Gtk.Grid ();
			library_grid.set_column_spacing (BookwormApp.Constants.SPACING_WIDGETS);
			library_grid.set_row_spacing (BookwormApp.Constants.SPACING_WIDGETS);
			ScrolledWindow library_scroll = new ScrolledWindow (null, null);
			library_scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
			library_scroll.add (library_grid);

			//Create a footer to add/remove books
			Gtk.Box add_remove_footer_box = new Gtk.Box (Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_BUTTONS);
			//Set up Button for adding book
			Gtk.Image add_book_image = new Gtk.Image ();
			add_book_image.set_from_file (BookwormApp.Constants.ADD_BOOK_ICON_IMAGE_LOCATION);
			Gtk.Button add_book_button = new Gtk.Button ();
			add_book_button.set_image (add_book_image);
			//Set up Button for removing book
			Gtk.Image remove_book_image = new Gtk.Image ();
			remove_book_image.set_from_file (BookwormApp.Constants.REMOVE_BOOK_ICON_IMAGE_LOCATION);
			Gtk.Button remove_book_button = new Gtk.Button ();
			remove_book_button.set_image (remove_book_image);

			//Set up contents of the add/remove books footer label
			add_remove_footer_box.pack_start (add_book_button, false, true, 0);
			add_remove_footer_box.pack_start (remove_book_button, false, true, 0);

			//add all components to ui box for selecting a book
			bookSelection_ui_box.pack_start (library_scroll, true, true, 0);
      bookSelection_ui_box.pack_start (add_remove_footer_box, false, true, 0);

			//Create the UI for reading a selected book
			bookReading_ui_box = new Gtk.Box (Orientation.VERTICAL, 0);
			//create the webview to display page content
			WebKit.Settings webkitSettings = new WebKit.Settings();
	    webkitSettings.set_allow_file_access_from_file_urls (true);
	    webkitSettings.set_default_font_family("helvetica");
			//webkitSettings.set_allow_universal_access_from_file_urls(true);
	    webkitSettings.set_auto_load_images(true);
	    aWebView = new WebKit.WebView.with_settings(webkitSettings);
			//aWebView.set_zoom_level (6.0); // use this for page zooming

			//create book reading footer
			Gtk.Box book_reading_footer_box = new Gtk.Box (Orientation.HORIZONTAL, 0);

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

			//Set up contents of the footer label
			Gtk.Label pageNumberLabel = new Label("");
			book_reading_footer_box.pack_start (back_button, false, true, 0);
			book_reading_footer_box.pack_start (pageNumberLabel, true, true, 0);
			book_reading_footer_box.pack_end (forward_button, false, true, 0);

			//add all components to ui box for book reading
			bookReading_ui_box.pack_start (aWebView, true, true, 0);
      bookReading_ui_box.pack_start (book_reading_footer_box, false, true, 0);

			//Add all ui components to the main UI box
			main_ui_box.pack_start(bookSelection_ui_box, true, true, 0);
			main_ui_box.pack_end(bookReading_ui_box, true, true, 0);

			//Add all UI action listeners
			aWebView.context_menu.connect (() => {
				//TO-DO: Build context menu for reading ebook
				return true;//stops webview default context menu from loading
			});
			forward_button.clicked.connect (() => {
				//get object for this ebook
				aBook = libraryViewMap.get(locationOfEBookCurrentlyRead);
				aBook = BookwormApp.ePubReader.renderPage(aWebView, aBook, "FORWARD");
			});
			back_button.clicked.connect (() => {
				//get object for this ebook
				aBook = libraryViewMap.get(locationOfEBookCurrentlyRead);
				aBook = BookwormApp.ePubReader.renderPage(aWebView, aBook, "BACKWARD");
			});
			add_book_button.clicked.connect (() => {
				string pathToSelectedBook = selectBookFileChooser();
				aBook = new BookwormApp.Book();
				aBook.setBookLocation(pathToSelectedBook);
				addBookToLibrary(aBook);
			});
			remove_book_button.clicked.connect (() => {
				removeBookFromLibrary();
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

			debug("Completed creation of main windows components...");
			return main_ui_box;
		}

		public void ensureRequiredSetUp(){
			//check and create directory for extracting contents of ebook
	    BookwormApp.Utils.fileOperations("CREATEDIR", BookwormApp.Constants.EPUB_EXTRACTION_LOCATION, "", "");
		}

		public void removeBookFromLibrary(){
			/*
			Gtk.EventBox aEventBox = libraryViewEventBoxWidgets.get("/home/sid/Documents/Projects/bookworm/ebooks/J. K. Rowling - Harry Potter and the Chamber of Secrets.epub");
			debug("eventbox to be removed:"+aEventBox.get_child_visible().to_string());
			//library_grid.remove(aEventBox);
			aEventBox.destroy();
			libraryViewMap.unset("/home/sid/Documents/Projects/bookworm/ebooks/J. K. Rowling - Harry Potter and the Chamber of Secrets.epub");
			window.show_all();
			BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[0];
			toggleUIState();
			*/
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
			//check if the selected eBook exists
			string eBookLocation = aBook.getBookLocation();
			File eBookFile = File.new_for_path (eBookLocation);
			if(eBookFile.query_exists() && eBookFile.query_file_type(0) != FileType.DIRECTORY){
				debug("Choosen eBook = " + eBookLocation);
				//create temp location for extraction of eBook
				string extractionLocation = BookwormApp.Constants.EPUB_EXTRACTION_LOCATION + File.new_for_path(eBookLocation).get_basename();
				aBook.setBookExtractionLocation(extractionLocation);
				//check and create directory for extracting contents of ebook
		    BookwormApp.Utils.fileOperations("CREATEDIR", extractionLocation, "", "");
		    //unzip eBook contents into temp location
		    BookwormApp.Utils.execute_sync_command("unzip -o \"" + eBookLocation + "\" -d \""+ extractionLocation +"\"");
				debug("eBook extracted into folder:"+extractionLocation);
				//determine location of eBook cover image
				aBook = BookwormApp.ePubReader.getBookCoverImageLocation(aBook);
				//add book details to libraryView Map
				libraryViewMap.set(eBookLocation, aBook);
				locationOfEBookCurrentlyRead = eBookLocation;
				debug ("No of books in library:"+libraryViewMap.size.to_string());
				//add eBook cover image to library view
				updateLibraryView(aBook);
			}else{
				debug("No ebook selected");
			}
		}

		public void updateLibraryView(BookwormApp.Book aBook){
			string bookCoverLocation = aBook.getBookCoverLocation();
			debug("Updating Library for cover:"+bookCoverLocation);
			Gtk.EventBox aEventBox = new Gtk.EventBox();
			Gdk.Pixbuf aBookCover = new Gdk.Pixbuf.from_file_at_scale(bookCoverLocation, 150, 200, false);
			Gtk.Image aCoverImage = new Gtk.Image.from_pixbuf(aBookCover);
			if(!aBook.getIsBookCoverImagePresent()){
				Gtk.Overlay aOverlayImage = new Gtk.Overlay();
				aOverlayImage.add(aCoverImage);
				Gtk.Label overlayTextLabel = new Gtk.Label("<b>"+aBook.getBookTitle()+"</b>");
				overlayTextLabel.set_use_markup (true);
				overlayTextLabel.set_line_wrap (true);
				aOverlayImage.add_overlay(overlayTextLabel);
				aEventBox.add(aOverlayImage);
			}else{
    		aEventBox.add(aCoverImage);
			}
			//set the book object as a property of the eventbox
			aEventBox.set_property ("BOOK_OBJECT", aBook);
			//add eventbox widet to a hashmap for later removal
			libraryViewEventBoxWidgets.set(aBook.getBookLocation(), aEventBox);
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
			lastBookUpdatedIntoLibraryGrid = aEventBox;
			window.show_all();
			BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[0];
			toggleUIState();
			//add listener for book cover EventBox
			aEventBox.button_press_event.connect (() => {
				debug("Initiated process for reading eBook:"+aBook.getBookLocation());
				readSelectedBook(aBook);
				return true;
			});
		}

		public void readSelectedBook(owned BookwormApp.Book aBook){
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
		}

		public void toggleUIState(){
			if(BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[0]){
				//Only show the UI for selecting a book
				bookReading_ui_box.set_visible(false);
				bookSelection_ui_box.set_visible(true);
			}else{
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
