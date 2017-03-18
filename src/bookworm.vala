/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and is the main Application class
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
		private static Bookworm application;
		private static bool isBookwormRunning = false;
		public int exitCodeForCommand = 0;
		public static string bookworm_config_path = GLib.Environment.get_user_config_dir ()+"/bookworm";

		public static string[] commandLineArgs;
		public unowned string[] startArgs;
		public StringBuilder spawn_async_with_pipes_output = new StringBuilder("");

		public static BookwormApp.Settings settings;
		public Gtk.Window window;
		public Gtk.Box bookWormUIBox;
		public static WebKit.WebView aWebView;
		public ePubReader aReader;
		public Granite.Widgets.Welcome welcomeWidget;
		public Gtk.Box bookLibrary_ui_box;
		public static Gtk.Box bookReading_ui_box;
		public static Gtk.EventBox book_reading_footer_eventbox;
		public static Gtk.Box book_reading_footer_box;
		public Gtk.Button library_view_button;
		public Gtk.Button content_list_button;
		public Gtk.Box textSizeBox;
		public ScrolledWindow library_scroll;
		public Gtk.FlowBox library_grid;
		public Gdk.Pixbuf bookSelectionPix;
		public Gdk.Pixbuf bookSelectedPix;
		public Gtk.Image bookSelectionImage;
		public Gtk.InfoBar infobar;
		public Gtk.Label infobarLabel;

		public static string BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[0];
		public static Gee.HashMap<string, BookwormApp.Book> libraryViewMap = new Gee.HashMap<string, BookwormApp.Book>();
		public static string locationOfEBookCurrentlyRead = "";
		public int countBooksAddedIntoLibraryRow = 0;

		construct {
			application_id = BookwormApp.Constants.bookworm_id;
			flags |= ApplicationFlags.HANDLES_COMMAND_LINE;
			program_name = BookwormApp.Constants.program_name;
			app_years = BookwormApp.Constants.app_years;
			build_version = BookwormApp.Constants.bookworm_version;
			app_icon = BookwormApp.Constants.app_icon;
			main_url = BookwormApp.Constants.main_url;
			bug_url = BookwormApp.Constants.bug_url;
			help_url = BookwormApp.Constants.help_url;
			translate_url = BookwormApp.Constants.translate_url;
			about_documenters = { null };
			about_artists = { null };
			about_authors = BookwormApp.Constants.about_authors;
			about_comments = BookwormApp.Constants.about_comments;
			about_translators = BookwormApp.Constants.translator_credits;
			about_license_type = BookwormApp.Constants.about_license_type;


		}

		private Bookworm() {
			Object (application_id: BookwormApp.Constants.bookworm_id, flags: ApplicationFlags.HANDLES_COMMAND_LINE);
			Intl.setlocale(LocaleCategory.MESSAGES, "");
			Intl.textdomain(GETTEXT_PACKAGE);
			Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "utf-8");
			Intl.bindtextdomain(GETTEXT_PACKAGE, "./locale");
			debug ("Completed setting Internalization...");
		}

		public static Bookworm getAppInstance(){
			if(application == null){
				//create an instance of bookworm
				application = new Bookworm();
			}else{
				//do nothing, return the existing instance
			}
			return application;
		}

		public override int command_line (ApplicationCommandLine command_line) {
			commandLineArgs = command_line.get_arguments ();
			if("--help" in commandLineArgs || "-h" in commandLineArgs || "--version" in commandLineArgs){
				int res = processCommandLine (command_line);
			}else{
				activate();
			}
			return 0;
		}

		public int processCommandLine (ApplicationCommandLine command_line) {
			bool command_line_option_version = false;
			bool command_line_option_debug = false;
			string command_line_option_path = "";

			OptionEntry[] options = new OptionEntry[3];
			options[0] = { "version", 0, 0, OptionArg.NONE, ref command_line_option_version, _("Display version number"), null };
			options[1] = { "debug", 0, 0, OptionArg.NONE, ref command_line_option_debug, _("Run Bookworm in debug mode"), null };
			options[2] = { "path", 0, 0, OptionArg.NONE, ref command_line_option_path, _("PATH"), _("Open multiple files with Bookworm")};
			add_main_option_entries (options);
			string[] args = command_line.get_arguments ();
			startArgs = args;
			try {
				var opt_context = new OptionContext ("- bookworm");
				opt_context.set_help_enabled (true);
				opt_context.add_main_entries (options, null);
				opt_context.parse (ref startArgs);
			}catch (OptionError e) {
				info ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
				info ("error: %s\n", e.message);
				return 0;
			}
			//check and run nutty based on command line option
			if(command_line_option_debug){
				debug ("Bookworm running in debug mode...");
			}
			if(command_line_option_version){
				print("bookworm version :"+Constants.bookworm_version+"\n");
				return 0;
			}
			return 0;
		}

		public override void activate() {
			//proceed if Bookworm is not running already
			if(!isBookwormRunning){
				print("No. of arguments:"+commandLineArgs.length.to_string());
				
				debug("Starting to activate Gtk Window for Bookworm...");
				window = new Gtk.Window ();
				add_window (window);

				//retrieve Settings
				settings = BookwormApp.Settings.get_instance();
				//set window attributes from saved settings
				if(settings.window_is_maximized){
					window.maximize();
				}else{
					if(settings.window_width > 0 && settings.window_height > 0){
						window.set_default_size(settings.window_width, settings.window_height);
					}else{
						window.set_default_size(1200, 700);
					}
				}
				window.set_border_width (0);
				window.set_position (Gtk.WindowPosition.CENTER);
				window.window_position = Gtk.WindowPosition.CENTER;
				//set the minimum size of the window on minimize
				window.set_size_request (600, 350);

				//set css provider
				var cssProvider = new Gtk.CssProvider();
				try{
					cssProvider.load_from_path(BookwormApp.Constants.CSS_LOCATION);
				}catch(GLib.Error e){
					warning("Stylesheet could not be loaded. Error:"+e.message);
				}
				Gtk.StyleContext.add_provider_for_screen(
													Gdk.Screen.get_default(),
													cssProvider,
													Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
												 );

				//add window components
				window.set_titlebar (BookwormApp.AppHeaderBar.create_headerbar());
				createWelcomeScreen();
				bookWormUIBox = createBoookwormUI();
				//load saved books from DB and add them to Library view
				loadBookwormState();
				//show welcome screen if no book is present in library instead of the normal library view
				if(libraryViewMap.size == 0){
					window.add(welcomeWidget);
				}else{
					window.add(bookWormUIBox);
				}
				window.show_all();
				toggleUIState();

				//capture window re-size events and save the window size
				window.size_allocate.connect(() => {
					//save books information to database
					saveWindowState();
				});
				//Exit Application Event
				window.destroy.connect (() => {
					//save books information to database
					saveBooksState();
				});
				isBookwormRunning = true;
				debug("Sucessfully activated Gtk Window for Bookworm...");
			}else{
					//A instance of bookworm is already running
					//TODO: Maximize the Bookworm window if it is minimized
			}
		}

		public override void open (File[] files, string hint) {
			debug("Starting open method with hint:"+hint);
		}

		public Granite.Widgets.Welcome createWelcomeScreen(){
			//Create a welcome screen for view of library with no books
			welcomeWidget = new Granite.Widgets.Welcome (BookwormApp.Constants.TEXT_FOR_WELCOME_MESSAGE_TITLE, BookwormApp.Constants.TEXT_FOR_WELCOME_MESSAGE_SUBTITLE);
			Gtk.Image? openFolderImage = new Gtk.Image.from_icon_name("document-open", Gtk.IconSize.DIALOG);
			welcomeWidget.append_with_image (openFolderImage, "Open", BookwormApp.Constants.TEXT_FOR_WELCOME_OPENDIR_MESSAGE);

			//Add action for adding a book on the library view
			welcomeWidget.activated.connect (() => {
				ArrayList<string> selectedEBooks = selectBookFileChooser();
				foreach(string pathToSelectedBook in selectedEBooks){
					BookwormApp.Book aBookBeingAdded = new BookwormApp.Book();
					aBookBeingAdded.setBookLocation(pathToSelectedBook);
					//the book will be updated to the libraryView Map within the addBookToLibrary function
					addBookToLibrary(aBookBeingAdded);
				}
				//remove the welcome widget from main window
				window.remove(welcomeWidget);
				window.add(bookWormUIBox);
				bookWormUIBox.show_all();
				toggleUIState();
			});
			return welcomeWidget;
		}

		public Gtk.Box createBoookwormUI() {
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

			//Create a footer to select/add/remove books
			Gtk.Box add_remove_footer_box = new Gtk.Box (Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_BUTTONS);
			add_remove_footer_box.set_border_width(BookwormApp.Constants.SPACING_BUTTONS);
			//Set up contents of the add/remove books footer label
			add_remove_footer_box.pack_start (select_book_button, false, true, 0);
			add_remove_footer_box.pack_start (add_book_button, false, true, 0);
			add_remove_footer_box.pack_start (remove_book_button, false, true, 0);

			//Create a MessageBar to show
			infobar = new Gtk.InfoBar ();
			infobarLabel = new Gtk.Label("");
			Gtk.Container infobarContent = infobar.get_content_area ();
			infobar.set_message_type (MessageType.INFO);
			infobarContent.add (infobarLabel);
			infobar.set_show_close_button (true);
			infobar.response.connect(on_info_bar_closed);
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
			aWebView.set_zoom_level(settings.zoom_level);
			webkitSettings.set_enable_javascript(true);

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
				currentBookForForward = libraryViewMap.get(locationOfEBookCurrentlyRead);
				debug("Initiating read forward for eBook:"+currentBookForForward.getBookLocation());
				currentBookForForward = BookwormApp.ePubReader.renderPage(aWebView, currentBookForForward, "FORWARD");
				//update book details to libraryView Map
				libraryViewMap.set(currentBookForForward.getBookLocation(), currentBookForForward);
				locationOfEBookCurrentlyRead = currentBookForForward.getBookLocation();
				//set the focus to the webview to capture keypress events
				aWebView.grab_focus();
			});
			//Add action on the backward button for reading
			back_button.clicked.connect (() => {
				//get object for this ebook and call the next page
				BookwormApp.Book currentBookForReverse = new BookwormApp.Book();
				currentBookForReverse = libraryViewMap.get(locationOfEBookCurrentlyRead);
				debug("Initiating read previous for eBook:"+currentBookForReverse.getBookLocation());
				currentBookForReverse = BookwormApp.ePubReader.renderPage(aWebView, currentBookForReverse, "BACKWARD");
				//update book details to libraryView Map
				libraryViewMap.set(currentBookForReverse.getBookLocation(), currentBookForReverse);
				locationOfEBookCurrentlyRead = currentBookForReverse.getBookLocation();
				//set the focus to the webview to capture keypress events
				aWebView.grab_focus();
			});
			//Add action for adding a book on the library view
			add_book_button.clicked.connect (() => {
				ArrayList<string> selectedEBooks = selectBookFileChooser();
				foreach(string pathToSelectedBook in selectedEBooks){
					BookwormApp.Book aBookBeingAdded = new BookwormApp.Book();
					aBookBeingAdded.setBookLocation(pathToSelectedBook);
					//the book will be updated to the libraryView Map within the addBookToLibrary function
					addBookToLibrary(aBookBeingAdded);
				}
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
						BookwormApp.Book aBookLeftKeyPress = libraryViewMap.get(locationOfEBookCurrentlyRead);
						aBookLeftKeyPress = BookwormApp.ePubReader.renderPage(aWebView, aBookLeftKeyPress, "BACKWARD");
						//update book details to libraryView Map
						libraryViewMap.set(aBookLeftKeyPress.getBookLocation(), aBookLeftKeyPress);
					}
			    if (ev.keyval == Gdk.Key.Right) {// Right key pressed, move page forward
						//get object for this ebook
						BookwormApp.Book aBookRightKeyPress = libraryViewMap.get(locationOfEBookCurrentlyRead);
						aBookRightKeyPress = BookwormApp.ePubReader.renderPage(aWebView, aBookRightKeyPress, "FORWARD");
						//update book details to libraryView Map
						libraryViewMap.set(aBookRightKeyPress.getBookLocation(), aBookRightKeyPress);
					}
			    return false;
			});
			//capture the url clicked on the webview and action the navigation type clicks
			aWebView.decide_policy.connect ((decision, type) => {
				if(type == WebKit.PolicyDecisionType.NAVIGATION_ACTION){
					WebKit.NavigationPolicyDecision aNavDecision = (WebKit.NavigationPolicyDecision)decision;
					WebKit.NavigationAction aNavAction = aNavDecision.get_navigation_action();
					WebKit.URIRequest aURIReq = aNavAction.get_request ();

					BookwormApp.Book aBook = libraryViewMap.get(locationOfEBookCurrentlyRead);
					//Remove %20 and file:/// from the URL if present
					string url_clicked_on_webview = aURIReq.get_uri().replace("%20"," ").replace(BookwormApp.Constants.PREFIX_FOR_FILE_URL, "").strip();
					debug("URL Captured:"+url_clicked_on_webview);
					//URL matches the content list of URLs
					if(aBook.getBookContentList().contains(url_clicked_on_webview)){
						aBook.setBookPageNumber(aBook.getBookContentList().index_of(url_clicked_on_webview));
						//update book details to libraryView Map
						libraryViewMap.set(aBook.getBookLocation(), aBook);
						//Set the mode back to Reading mode
						BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[1];
						toggleUIState();
						debug("URL is initiated from Bookworm Contents, Book page number set at:"+aBook.getBookPageNumber().to_string());
					//URL does not match the Bookworm content URLs
					}else{
						//Remove '#' on the end of the URL if present and try to match contents (TODO: See how exact navigation can be done with #)
						if(url_clicked_on_webview.index_of("#") != -1){
							url_clicked_on_webview = url_clicked_on_webview.slice(0, url_clicked_on_webview.index_of("#"));
						}
						url_clicked_on_webview = BookwormApp.Utils.getFullPathFromFilename(aBook.getBookExtractionLocation(), url_clicked_on_webview).strip();
						//Modify the URL by removing # at the end and see if it matches the content URL
						if(aBook.getBookContentList().contains(url_clicked_on_webview)){
							aBook.setBookPageNumber(aBook.getBookContentList().index_of(url_clicked_on_webview));
							aBook = BookwormApp.ePubReader.renderPage(aWebView, aBook, "");
							//update book details to libraryView Map
							libraryViewMap.set(aBook.getBookLocation(), aBook);
							//Set the mode back to Reading mode
							BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[1];
							toggleUIState();
							debug("URL is initiated from Bookworm Contents, Book page number set at:"+aBook.getBookPageNumber().to_string());
						//URL is an external one and needs to be loaded on the User's browser
						}else{
							//TO-DO:
							//(1)keep Bookworm on the same page and
							//(2)open user's browser with the URL
						}
					}
				}
				return true;
			});

			debug("Completed creation of main window components...");
			return main_ui_box;
		}

		//Handle action for close of the InfoBar
		private void on_info_bar_closed(){
        infobar.hide();
		}

		public void loadBookwormState(){
			//check and create required directory structure
	    BookwormApp.Utils.fileOperations("CREATEDIR", BookwormApp.Constants.EPUB_EXTRACTION_LOCATION, "", "");
			BookwormApp.Utils.fileOperations("CREATEDIR", bookworm_config_path, "", "");
			BookwormApp.Utils.fileOperations("CREATEDIR", bookworm_config_path+"/covers/", "", "");
			//check if the database exists otherwise create database and required tables
			bool isDBPresent = BookwormApp.DB.initializeBookWormDB(bookworm_config_path);
			//Set the colour mode based on the user's last saved prefference setting
			if(BookwormApp.Constants.BOOKWORM_READING_MODE[1] == settings.reading_profile){
				applyProfile("NIGHT MODE");
			}else{
				//default to the Day Mode if no other mode is found in the settings
				applyProfile("DAY MODE");
			}
			//Fetch details of Books from the database and update the grid
			updateLibraryViewFromDB();
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

					//destroy the EventBox parent widget - this removes the book from the library grid
					lEventBox.get_parent().destroy();
					//destroy the EventBox widget
					lEventBox.destroy();
				}
			}
			library_grid.show_all();
			//loop through the removed books and remove them from the Library View Hashmap and Database
			foreach (string bookLocation in listOfBooksToBeRemoved) {
				BookwormApp.DB.removeBookFromDB(libraryViewMap.get(bookLocation));
				libraryViewMap.unset(bookLocation);
			}

			BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[0];
			updateLibraryViewForSelectionMode(null);
			toggleUIState();
		}

		public static void applyProfile(string profilename){

			debug("Starting to apply profile["+profilename+"]...");
			Gdk.RGBA rgba = Gdk.RGBA ();
			bool parseRGBA;
			switch(profilename){
				case "NIGHT MODE":
					parseRGBA = rgba.parse (BookwormApp.Constants.RGBA_HEX_BLACK);
					settings.reading_profile = BookwormApp.Constants.BOOKWORM_READING_MODE[1];
					Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
					break;
				case "DAY MODE":
					parseRGBA = rgba.parse (BookwormApp.Constants.RGBA_HEX_WHITE);
					settings.reading_profile = BookwormApp.Constants.BOOKWORM_READING_MODE[0];
					Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
					break;
				default:
					break;
			}
			aWebView.set_background_color (rgba);
			debug("Completed applying profile["+profilename+"]...");

		}

		public ArrayList<string> selectBookFileChooser(){
			ArrayList<string> eBookLocationList = new ArrayList<string>();
			//create a hashmap to hold details for the book
			Gee.HashMap<string,string> bookDetailsMap = new Gee.HashMap<string,string>();
	    //choose eBook using a File chooser dialog
			Gtk.FileChooserDialog aFileChooserDialog = BookwormApp.Utils.new_file_chooser_dialog (Gtk.FileChooserAction.OPEN, "Select eBook", window, true);
	    aFileChooserDialog.show_all ();
	    if (aFileChooserDialog.run () == Gtk.ResponseType.ACCEPT) {
	      SList<string> uris = aFileChooserDialog.get_uris ();
				foreach (unowned string uri in uris) {
					eBookLocationList.add(File.new_for_uri(uri).get_path ());
				}
				aFileChooserDialog.close();
	    }else{
	      aFileChooserDialog.close();
	    }
			return eBookLocationList;
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
					//parse ePub Book
					aBook = BookwormApp.ePubReader.parseEPubBook(aBook);
					//add book details to libraryView Map
					libraryViewMap.set(eBookLocation, aBook);
					//set the name of the book being currently read
					locationOfEBookCurrentlyRead = eBookLocation;
					//add eBook cover image to library view
					updateLibraryView(aBook);
					//insert book details to database
					BookwormApp.DB.addBookToDataBase(aBook);
					debug ("Completed adding book to ebook library. Number of books in library:"+libraryViewMap.size.to_string());
				}else{
					debug("No ebook found for adding to library");
				}
			}
		}

		public void updateLibraryView(owned BookwormApp.Book aBook){
			debug("Updating Library [Current Row Count:"+countBooksAddedIntoLibraryRow.to_string()+"] for cover:"+aBook.getBookCoverLocation());
			Gtk.EventBox aEventBox = new Gtk.EventBox();
			aEventBox.set_name(aBook.getBookLocation());
			Gtk.Overlay aOverlayImage = new Gtk.Overlay();
			Gtk.Image aCoverImage;
			string bookCoverLocation;

			if(!aBook.getIsBookCoverImagePresent()){
				//check if the default cover has been set and continue to use it
				if(aBook.getBookCoverLocation() == null || aBook.getBookCoverLocation().length < 1){
					//default Book Cover Image not set - select at random from the default covers
					bookCoverLocation = BookwormApp.Constants.DEFAULT_COVER_IMAGE_LOCATION.replace("N", GLib.Random.int_range(1, 6).to_string());
					aBook.setBookCoverLocation(bookCoverLocation);
				}
				Gdk.Pixbuf aBookCover = new Gdk.Pixbuf.from_file_at_scale(aBook.getBookCoverLocation(), 150, 200, false);
				aCoverImage = new Gtk.Image.from_pixbuf(aBookCover);
				aCoverImage.set_halign(Align.START);
				aCoverImage.set_valign(Align.START);
				aOverlayImage.add(aCoverImage);
				Gtk.Label overlayTextLabel = new Gtk.Label("<b>"+aBook.getBookTitle()+"</b>");
				overlayTextLabel.set_xalign(0.0f);
				overlayTextLabel.set_margin_start(12);
				overlayTextLabel.set_use_markup (true);
				overlayTextLabel.set_line_wrap (true);
				aOverlayImage.add_overlay(overlayTextLabel);
				aEventBox.add(aOverlayImage);
			}else{
				//use the cover image extracted from the epub file
				Gdk.Pixbuf aBookCover = new Gdk.Pixbuf.from_file_at_scale(aBook.getBookCoverLocation(), 150, 200, false);
				aCoverImage = new Gtk.Image.from_pixbuf(aBookCover);
				aCoverImage.set_halign(Align.START);
				aCoverImage.set_valign(Align.START);
				aOverlayImage.add(aCoverImage);
				aEventBox.add(aOverlayImage);
			}
			library_grid.add (aEventBox);

			//set gtk objects into Book objects
			aBook.setCoverImage (aCoverImage);
			aBook.setEventBox(aEventBox);
			aBook.setOverlayImage(aOverlayImage);

			//set the view mode to library view
			BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[0];
			library_grid.show_all();
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
		}

		public void updateLibraryViewForSelectionMode(owned BookwormApp.Book? lBook){
			Gtk.Image aCoverImage;
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
						//check if the default cover has been set and continue to use it
						if(((BookwormApp.Book)book).getBookCoverLocation() == null || ((BookwormApp.Book)book).getBookCoverLocation().length < 1){
							//default Book Cover Image not set - select at random from the default covers
							string bookCoverLocation = BookwormApp.Constants.DEFAULT_COVER_IMAGE_LOCATION.replace("N", GLib.Random.int_range(1, 6).to_string());
							((BookwormApp.Book)book).setBookCoverLocation(bookCoverLocation);
						}
						Gdk.Pixbuf aBookCover = new Gdk.Pixbuf.from_file_at_scale(((BookwormApp.Book)book).getBookCoverLocation(), 150, 200, false);
						aCoverImage = new Gtk.Image.from_pixbuf(aBookCover);
						aCoverImage.set_halign(Align.START);
						aCoverImage.set_valign(Align.START);
						lOverlayImage.add(aCoverImage);//use the default Book Cover Image
						Gtk.Label overlayTextLabel = new Gtk.Label("<b>"+((BookwormApp.Book)book).getBookTitle()+"</b>");
						overlayTextLabel.set_xalign(0.0f);
						overlayTextLabel.set_margin_start(12);
						overlayTextLabel.set_use_markup (true);
						overlayTextLabel.set_line_wrap (true);
						lOverlayImage.add_overlay(overlayTextLabel);
						lEventBox.add(lOverlayImage);
					}else{
						Gdk.Pixbuf aBookCover = new Gdk.Pixbuf.from_file_at_scale(((BookwormApp.Book)book).getBookCoverLocation(), 150, 200, false);
						aCoverImage = new Gtk.Image.from_pixbuf(aBookCover);
						aCoverImage.set_halign(Align.START);
						aCoverImage.set_valign(Align.START);
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
					//check if the default cover has been set and continue to use it
					if(lBook.getBookCoverLocation() == null || lBook.getBookCoverLocation().length < 1){
						//default Book Cover Image not set - select at random from the default covers
						string bookCoverLocation = BookwormApp.Constants.DEFAULT_COVER_IMAGE_LOCATION.replace("N", GLib.Random.int_range(1, 6).to_string());
						lBook.setBookCoverLocation(bookCoverLocation);
					}
					Gdk.Pixbuf aBookCover = new Gdk.Pixbuf.from_file_at_scale(lBook.getBookCoverLocation(), 150, 200, false);
					aCoverImage = new Gtk.Image.from_pixbuf(aBookCover);
					aCoverImage.set_halign(Align.START);
					aCoverImage.set_valign(Align.START);
					lOverlayImage.add(aCoverImage);//use the default Book Cover Image
					Gtk.Label overlayTextLabel = new Gtk.Label("<b>"+lBook.getBookTitle()+"</b>");
					overlayTextLabel.set_xalign(0.0f);
					overlayTextLabel.set_margin_start(12);
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
					aCoverImage = new Gtk.Image.from_pixbuf(aBookCover);
					aCoverImage.set_halign(Align.START);
					aCoverImage.set_valign(Align.START);
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
			library_grid.show_all();
			toggleUIState();
		}

		public void readSelectedBook(owned BookwormApp.Book aBook){
			//Extract and Parse the eBook (this will overwrite the contents already extracted)
			aBook = BookwormApp.ePubReader.parseEPubBook(aBook);
			//check if ebook was parsed sucessfully
			if(!aBook.getIsBookParsed()){
				StringBuilder warningMessage = new StringBuilder("");
					warningMessage.append(BookwormApp.Constants.TEXT_FOR_RENDERING_ISSUE)
												.append(" : ")
												.append(aBook.getBookLocation());
				infobarLabel.set_text(warningMessage.str);
				infobar.set_message_type (MessageType.WARNING);
				infobar.show();
			}else{
				//render the contents of the current page of book
				aBook = BookwormApp.ePubReader.renderPage(aWebView, aBook, "");
				//update book details to libraryView Map
				libraryViewMap.set(aBook.getBookLocation(), aBook);
				locationOfEBookCurrentlyRead = aBook.getBookLocation();
				//Update header title
				BookwormApp.AppHeaderBar.get_headerbar().subtitle = aBook.getBookTitle();
				//change the application view to Book Reading mode
				BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[1];
				toggleUIState();
			}
		}

		public void updateLibraryViewFromDB(){
			ArrayList<BookwormApp.Book> listOfBooks = BookwormApp.DB.getBooksFromDB();
			foreach (BookwormApp.Book book in listOfBooks){
				//add the book to the UI
				updateLibraryView(book);
				//add book details to libraryView Map
				libraryViewMap.set(book.getBookLocation(), book);
			}
		}

		public void toggleUIState(){
			//hide the inforbar if there is no text in it
			if(infobarLabel.get_text().length < 1){
				infobar.hide();
			}

			//UI for Library View
			if(BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[0] ||
				 BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[2] ||
				 BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[3]
				){
				content_list_button.set_visible(false);
				library_view_button.set_visible(false);
				bookLibrary_ui_box.set_visible(true);
				bookReading_ui_box.set_visible(false);
				BookwormApp.Info.info_box.set_visible(false);
				textSizeBox.set_visible(false);
			}
			//Reading Mode
			if(BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[1]){
				//UI for Reading View
				content_list_button.set_visible(true);
				library_view_button.set_visible(true);
				library_view_button.set_label(BookwormApp.Constants.TEXT_FOR_LIBRARY_BUTTON);
				bookLibrary_ui_box.set_visible(false);
				bookReading_ui_box.set_visible(true);
				BookwormApp.Info.info_box.set_visible(false);
				textSizeBox.set_visible(true);
			}
			//Book Meta Data / Content View Mode
			if(BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[4]){
				//UI for Reading View
				BookwormApp.Info.info_box.show_all();
				content_list_button.set_visible(true);
				library_view_button.set_visible(true);
				library_view_button.set_label(BookwormApp.Constants.TEXT_FOR_RESUME_BUTTON);
				bookLibrary_ui_box.set_visible(false);
				bookReading_ui_box.set_visible(false);
				BookwormApp.Info.info_box.set_visible(true);
				BookwormApp.Info.stack.set_visible_child_name ("content-list");
				textSizeBox.set_visible(false);
			}
		}

		public async void saveBooksState (){
				foreach (var book in libraryViewMap.values){
					//Update the book details to the database
					BookwormApp.DB.updateBookToDataBase((BookwormApp.Book)book);
					debug("Completed saving the book data into DB");
					Idle.add (saveBooksState.callback);
					yield;
				}
		}

		public void saveWindowState(){
			int width;
      int height;
      int x;
			int y;
			window.get_size (out width, out height);
			window.get_position (out x, out y);
			if(settings.pos_x != x || settings.pos_y != y){
				settings.pos_x = x;
      	settings.pos_y = y;
			}
			if(settings.window_width != width || settings.window_height != height){
      	settings.window_width = width;
				settings.window_height = height;
			}
			if(window.is_maximized == true){
				settings.window_is_maximized = true;
			}else{
				settings.window_is_maximized = false;
			}
			settings.zoom_level = aWebView.get_zoom_level();
			/*
			debug("Window state saved in Settings with values
						 width="+width.to_string()+",
						 height="+height.to_string()+",
						 x="+x.to_string()+",
						 y="+y.to_string()
					 );
			*/
		}
	}
}
