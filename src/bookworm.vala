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

public class BookwormApp.Bookworm : Granite.Application {
	private static Bookworm application;
	private static bool isBookwormRunning = false;
	public int exitCodeForCommand = 0;
	public static string bookworm_config_path = GLib.Environment.get_user_config_dir ()+"/bookworm";

	public static string[] commandLineArgs;
	private static bool command_line_option_version = false;
	private static bool command_line_option_debug = false;
	private static OptionEntry[] options;

	public StringBuilder spawn_async_with_pipes_output = new StringBuilder("");

	public static BookwormApp.Settings settings;
	public static Gtk.ApplicationWindow window;
	public static Gtk.IconTheme default_theme;
	public static Gtk.Box bookWormUIBox;
	public static Granite.Widgets.Welcome welcomeWidget;
	public static Gtk.Button library_view_button;
	public static Gtk.Button content_list_button;
	public static Gtk.Button prefButton;
	public static Gdk.Pixbuf bookSelectionPix;
	public static Gdk.Pixbuf bookSelectedPix;
	public static Gtk.Image bookSelectionImage;

	public static string BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[0];
	public static Gee.HashMap<string, BookwormApp.Book> libraryViewMap = new Gee.HashMap<string, BookwormApp.Book>();
	public static string locationOfEBookCurrentlyRead = "";
	public static string[] pathsOfBooksToBeAdded;
	public static int noOfBooksAddedFromCommand = 0;
	public static bool isBookBeingAddedToLibrary = false;

	construct {
		application_id = BookwormApp.Constants.bookworm_id;
		flags |= ApplicationFlags.HANDLES_COMMAND_LINE;
		program_name = BookwormApp.Constants.program_name;
		exec_name = "bookworm";
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

		options = new OptionEntry[3];
		options[0] = { "version", 0, 0, OptionArg.NONE, ref command_line_option_version, _("Display version number"), null };
		options[1] = { "debug", 0, 0, OptionArg.NONE, ref command_line_option_debug, _("Run Bookworm in debug mode"), null };
		add_main_option_entries (options);
	}

	private Bookworm() {
		Intl.setlocale(LocaleCategory.MESSAGES, "");
		Intl.textdomain(GETTEXT_PACKAGE);
		Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "utf-8");
		Intl.bindtextdomain(GETTEXT_PACKAGE, "./locale");
		debug ("Completed setting Internalization...");
	}

	public static Bookworm getAppInstance(){
		if(application == null){
			application = new Bookworm();
		}else{
			//do nothing, return the existing instance
		}
		return application;
	}

	public override int command_line (ApplicationCommandLine command_line) {
		commandLineArgs = command_line.get_arguments ();
		activate();
		return 0;
	}

	public int processCommandLine (string[] args) {
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
			print("\nbookworm version "+Constants.bookworm_version+"\n");
			return 0;
		}else{
			activate();
			return 0;
		}
	}

	public override void activate() {
		debug("Starting activate method");
		//proceed if Bookworm is not running already
		if(!isBookwormRunning){
			debug("Starting to activate Gtk Window for Bookworm...");
			window = new Gtk.ApplicationWindow (this);
			default_theme = Gtk.IconTheme.get_default();

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
			window.get_style_context ().add_class ("rounded");
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
			BookwormApp.AppWindow.createWelcomeScreen();
			bookWormUIBox = BookwormApp.AppWindow.createBoookwormUI();
			//load saved books from DB and add them to Library view
			loadBookwormState();
			//show welcome screen if no book is present in library instead of the normal library view
			if(libraryViewMap.size == 0){
				window.add(welcomeWidget);
			}else{
				window.add(bookWormUIBox);
			}
			add_window (window);
			window.show_all();
			toggleUIState();

			//capture window re-size events and save the window size
			window.size_allocate.connect(() => {
				//save books information to database
				saveWindowState();
			});
			//Exit Application Event
			window.destroy.connect (() => {
				//Perform close down activities
				closeBookWorm();
			});
			isBookwormRunning = true;
			debug("Sucessfully activated Gtk Window for Bookworm...");
		}else{
				window.present();
				debug("A instance of bookworm is already running...");
		}
		//check if any books needed to be added/opened - if eBook(s) were opened from Files
		if(commandLineArgs.length > 1){
			pathsOfBooksToBeAdded = new string[commandLineArgs.length];
			pathsOfBooksToBeAdded = commandLineArgs;
			//Display the progress bar
			BookwormApp.AppWindow.bookAdditionBar.show();
			isBookBeingAddedToLibrary = true;
			//handle the case if the welcome screen is shown
			if(libraryViewMap.size == 0){
				//remove the welcome widget from main window
				window.remove(welcomeWidget);
				//add the library view to the window
				window.add(bookWormUIBox);
				bookWormUIBox.show_all();
				toggleUIState();
			}
			addBooksToLibrary ();
		}
		toggleUIState();
		debug("Ending activate method");
	}

	public override void open (File[] files, string hint) {

	}

	public static async void addBooksToLibrary (){
		debug("Starting to add books....");
		//loop through the command line and add books to library
		foreach(string pathToSelectedBook in pathsOfBooksToBeAdded){
			if("bookworm" != pathToSelectedBook){//ignore the first command which is the application name
				BookwormApp.Book aBookBeingAdded = new BookwormApp.Book();
				aBookBeingAdded.setBookLocation(pathToSelectedBook);
				//the book will be updated to the libraryView Map within the addBookToLibrary function
				addBookToLibrary(aBookBeingAdded);
				noOfBooksAddedFromCommand++;
				BookwormApp.AppWindow.bookAdditionBar.set_text (pathToSelectedBook);
				if(pathsOfBooksToBeAdded.length > 1){
					BookwormApp.AppWindow.bookAdditionBar.set_pulse_step ((noOfBooksAddedFromCommand/(pathsOfBooksToBeAdded.length-1)));
					BookwormApp.AppWindow.bookAdditionBar.pulse();
				}
				Idle.add (addBooksToLibrary.callback);
				yield;
			}
		}
		//open the book added if only one book path is present on command line
		if(pathsOfBooksToBeAdded.length == 2 && "bookworm" == pathsOfBooksToBeAdded[0]){
			readSelectedBook(libraryViewMap.get(commandLineArgs[1]));
		}
		debug("Completed adding book provided on commandline...");
		//Hide the progress bar
		BookwormApp.AppWindow.bookAdditionBar.hide();
		isBookBeingAddedToLibrary = false;
	}

	public void loadBookwormState(){
		//check and create required directory structure
    BookwormApp.Utils.fileOperations("CREATEDIR", BookwormApp.Constants.EBOOK_EXTRACTION_LOCATION, "", "");
		BookwormApp.Utils.fileOperations("CREATEDIR", bookworm_config_path, "", "");
		BookwormApp.Utils.fileOperations("CREATEDIR", bookworm_config_path+"/covers/", "", "");
		BookwormApp.Utils.fileOperations("CREATEDIR", bookworm_config_path+"/books/", "", "");
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

	public static void removeSelectedBooksFromLibrary(){
		ArrayList<string> listOfBooksToBeRemoved = new ArrayList<string> ();
		//loop through the Library View Hashmap
		foreach (BookwormApp.Book book in libraryViewMap.values){
			//check if the book selection flag to true and remove book
			if(book.getIsBookSelected()){
				//hold the books to be deleted in a list
				listOfBooksToBeRemoved.add(book.getBookLocation());
				Gtk.EventBox lEventBox = (Gtk.EventBox) book.getBookWidget("BOOK_EVENTBOX");
				//destroy the EventBox parent widget - this removes the book from the library grid
				lEventBox.get_parent().destroy();
				//destroy the EventBox widget
				lEventBox.destroy();
				//remove the cover image if it exists (ignore default covers)
				if(book.getBookCoverLocation().index_of(BookwormApp.Constants.DEFAULT_COVER_IMAGE_LOCATION.replace("-cover-N.png","")) == -1){
					BookwormApp.Utils.execute_sync_command("rm \""+book.getBookCoverLocation()+"\"");
				}
			}
		}
		BookwormApp.AppWindow.library_grid.show_all();
		//loop through the removed books and remove them from the Library View Hashmap, local cache and Database
		foreach (string bookLocation in listOfBooksToBeRemoved) {
			BookwormApp.DB.removeBookFromDB(libraryViewMap.get(bookLocation));
			libraryViewMap.unset(bookLocation);
		}

		BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[0];
		BookwormApp.Library.updateLibraryViewForSelectionMode(null);
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
		BookwormApp.AppWindow.aWebView.set_background_color (rgba);
		debug("Completed applying profile["+profilename+"]...");

	}

	public static void addBookToLibrary(owned BookwormApp.Book aBook){
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
				//insert book details to database and fetch the ID
				int bookID = BookwormApp.DB.addBookToDataBase(aBook);
				aBook.setBookId(bookID);
				/*Other than location, nothing is inserted into the DB for the book at this time.
				Mark book as opened in the session so that details for book are updated
				into DB when the application is closed - eBook parsing happens after the initial insert
				*/
				aBook.setBookLastModificationDate((new DateTime.now_utc().to_unix()).to_string());
				aBook.setWasBookOpened(true);
				//parse eBook to populate cache and book meta data
				aBook = genericParser(aBook);
				if(!aBook.getIsBookParsed()){
					BookwormApp.DB.removeBookFromDB(libraryViewMap.get(eBookLocation));
					BookwormApp.AppWindow.showInfoBar(aBook, MessageType.WARNING);
				}else{
					//add eBook cover image to library view
					BookwormApp.Library.updateLibraryView(aBook);
					//add book details to libraryView Map
					libraryViewMap.set(eBookLocation, aBook);
					//set the name of the book being currently read
					locationOfEBookCurrentlyRead = eBookLocation;
					debug ("Completed adding book to ebook library. Number of books in library:"+libraryViewMap.size.to_string());
				}
			}else{
				debug("No ebook found for adding to library");
			}
		}
	}

	public static void readSelectedBook(owned BookwormApp.Book aBook){
		//check if the extracted contents for the book exists
		if(BookwormApp.Bookworm.settings.is_local_storage_enabled &&
			"true" == BookwormApp.Utils.fileOperations("DIR_EXISTS", aBook.getBookExtractionLocation(), "", "") &&
			 aBook.getBookContentList().size > 0
		){
			//do nothing - extraction of book not required
		}else{
			//Extract and Parse the eBook (this will overwrite the contents already extracted)
			aBook = genericParser(aBook);
			//check if ebook was parsed sucessfully
			if(!aBook.getIsBookParsed()){
				BookwormApp.AppWindow.showInfoBar(aBook, MessageType.WARNING);
			}
		}
		//update book to mark it has been opened in this session
		aBook.setBookLastModificationDate((new DateTime.now_utc().to_unix()).to_string());
		aBook.setWasBookOpened(true);
		//update book details to libraryView Map
		libraryViewMap.set(aBook.getBookLocation(), aBook);
		locationOfEBookCurrentlyRead = aBook.getBookLocation();
		//Update header title
		BookwormApp.AppHeaderBar.get_headerbar().subtitle = aBook.getBookTitle();
		//change the application view to Book Reading mode
		BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[1];
		toggleUIState();
		//reset the contents of the search entry
		BookwormApp.Info.searchresults_scroll.get_child().destroy();
		//render the contents of the current page of book
		aBook = renderPage(aBook, "");
	}

	public void updateLibraryViewFromDB(){
		ArrayList<BookwormApp.Book> listOfBooks = BookwormApp.DB.getBooksFromDB();
		foreach (BookwormApp.Book book in listOfBooks){
			//add the book to the UI
			BookwormApp.Library.updateLibraryView(book);
		}
	}

	public static void toggleUIState(){
		//hide the inforbar if there is no text in it
		if(BookwormApp.AppWindow.infobarLabel.get_text().length < 1){
			BookwormApp.AppWindow.infobar.hide();
		}

		//UI for Library View
		if(BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[0] ||
			 BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[2] ||
			 BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[3]
			){
			BookwormApp.AppHeaderBar.headerSearchBar.set_placeholder_text(BookwormApp.Constants.TEXT_FOR_HEADERBAR_LIBRARY_SEARCH);
			content_list_button.set_visible(false);
			library_view_button.set_visible(false);
			BookwormApp.AppWindow.bookLibrary_ui_box.set_visible(true);
			BookwormApp.AppWindow.bookReading_ui_box.set_visible(false);
			BookwormApp.Info.info_box.set_visible(false);
			prefButton.set_visible(false);
			BookwormApp.AppHeaderBar.bookmark_active_button.set_visible(false);
			BookwormApp.AppHeaderBar.bookmark_inactive_button.set_visible(false);
			if(!isBookBeingAddedToLibrary)
				BookwormApp.AppWindow.bookAdditionBar.hide();
		}
		//Reading Mode
		if(BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[1]){
			//UI for Reading View
			BookwormApp.AppHeaderBar.headerSearchBar.set_placeholder_text(BookwormApp.Constants.TEXT_FOR_HEADERBAR_BOOK_SEARCH);
			content_list_button.set_visible(true);
			library_view_button.set_visible(true);
			library_view_button.set_label(BookwormApp.Constants.TEXT_FOR_LIBRARY_BUTTON);
			BookwormApp.AppWindow.bookLibrary_ui_box.set_visible(false);
			BookwormApp.AppWindow.bookReading_ui_box.set_visible(true);
			BookwormApp.Info.info_box.set_visible(false);
			prefButton.set_visible(true);
			handleBookMark("DISPLAY");
			BookwormApp.AppWindow.bookAdditionBar.hide();
		}
		//Book Meta Data / Content View Mode
		if(BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[4]){
			//UI for Reading View
			BookwormApp.AppHeaderBar.headerSearchBar.set_placeholder_text(BookwormApp.Constants.TEXT_FOR_HEADERBAR_BOOK_SEARCH);
			BookwormApp.Info.info_box.show_all();
			content_list_button.set_visible(true);
			library_view_button.set_visible(true);
			library_view_button.set_label(BookwormApp.Constants.TEXT_FOR_RESUME_BUTTON);
			BookwormApp.AppWindow.bookLibrary_ui_box.set_visible(false);
			BookwormApp.AppWindow.bookReading_ui_box.set_visible(false);
			BookwormApp.Info.info_box.set_visible(true);
			BookwormApp.Info.stack.set_visible_child_name ("content-list");
			prefButton.set_visible(false);
			BookwormApp.AppHeaderBar.bookmark_active_button.set_visible(false);
			BookwormApp.AppHeaderBar.bookmark_inactive_button.set_visible(false);
			BookwormApp.AppWindow.bookAdditionBar.hide();
		}
	}

	public async void closeBookWorm (){
			foreach (var book in libraryViewMap.values){
				//Update the book details to the database if it was opened in this session
				if(((BookwormApp.Book)book).getWasBookOpened()){
					BookwormApp.DB.updateBookToDataBase((BookwormApp.Book)book);
					debug("Completed saving the book data into DB");
				}
				Idle.add (closeBookWorm.callback);
				yield;
			}
			BookwormApp.Cleanup.cleanUp();
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
		settings.zoom_level = BookwormApp.AppWindow.aWebView.get_zoom_level();
		/*
		debug("Window state saved in Settings with values
					 width="+width.to_string()+",
					 height="+height.to_string()+",
					 x="+x.to_string()+",
					 y="+y.to_string()
				 );
		*/
	}

	public static BookwormApp.Book controlNavigation(owned BookwormApp.Book aBook){
		int currentContentLocation = aBook.getBookPageNumber();
		debug("In controlNavigation with currentContentLocation="+currentContentLocation.to_string());
		//check if Book can be moved back and disable back button otherwise
		if(currentContentLocation > 0){
			aBook.setIfPageBackward(true);
			BookwormApp.AppWindow.back_button.set_sensitive(true);
		}else{
			aBook.setIfPageBackward(false);
			BookwormApp.AppWindow.back_button.set_sensitive(false);
		}
		//check if Book can be moved forward and disable forward button otherwise
		if(currentContentLocation < (aBook.getBookContentList().size - 1)){
			aBook.setIfPageForward(true);
			BookwormApp.AppWindow.forward_button.set_sensitive(true);
		}else{
			aBook.setIfPageForward(false);
			BookwormApp.AppWindow.forward_button.set_sensitive(false);
		}
		return aBook;
	}

	public static BookwormApp.Book renderPage (owned BookwormApp.Book aBook, owned string direction){
		int currentContentLocation = aBook.getBookPageNumber();
		string searchText = "";

		//handle loading page with search string
		if(direction.index_of("SEARCH:") != -1){
			searchText = direction.replace("SEARCH:", "");
			direction = "SEARCH";
		}
		//Handle the case when the page number of the book is not set
    if(aBook.getBookPageNumber() == -1){
			aBook.setBookPageNumber(0);
      currentContentLocation = 0;
		}
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
				//TODO: Scroll the page to where the search text is present
				//WebKit.FindController awebkitController = BookwormApp.AppWindow.aWebView.get_find_controller ();
				//awebkitController.search (searchText, WebKit.FindOptions.CASE_INSENSITIVE, 1);
				break;

			default://This is for opening the current page of the book
				//No change of page number required
				break;
		}
		//render the content on webview
    BookwormApp.AppWindow.aWebView.load_html(BookwormApp.contentHandler.provideContent(aBook,currentContentLocation), BookwormApp.Constants.PREFIX_FOR_FILE_URL);
    //set the focus to the webview to capture keypress events
    BookwormApp.AppWindow.aWebView.grab_focus();
		//set the bookmak icon on the header
		handleBookMark("DISPLAY");
		//set the navigation controls
		aBook = BookwormApp.Bookworm.controlNavigation(aBook);
		return aBook;
	}

	public static bool libraryViewFilter (FlowBoxChild aEventBoxBook) {
		//execute filter only if the search text is not the default one or not blank
		if(BookwormApp.AppHeaderBar.headerSearchBar.get_text() != BookwormApp.Constants.TEXT_FOR_HEADERBAR_LIBRARY_SEARCH &&
			 BookwormApp.AppHeaderBar.headerSearchBar.get_text().strip() != ""
		){
			BookwormApp.Book aBook  = libraryViewMap.get(((EventBox)aEventBoxBook.get_child()).get_name());
			if((aBook.getBookLocation().up()).index_of(BookwormApp.AppHeaderBar.headerSearchBar.get_text().up()) != -1){
				return true;
			}
			else if((aBook.getBookTitle().up()).index_of(BookwormApp.AppHeaderBar.headerSearchBar.get_text().up()) != -1){
				return true;
			}
			else if((aBook.getBookAuthor().up()).index_of(BookwormApp.AppHeaderBar.headerSearchBar.get_text().up()) != -1){
				return true;
			}
			else if((aBook.getBookTags().up()).index_of(BookwormApp.AppHeaderBar.headerSearchBar.get_text().up()) != -1){
				return true;
			}
			else{
				return false;
			}
		}
		return true;
	}

	public static void handleBookMark(string action){
		//get the book being currently read
		BookwormApp.Book aBook = libraryViewMap.get(locationOfEBookCurrentlyRead);
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
			libraryViewMap.set(locationOfEBookCurrentlyRead, aBook);
		}
	}

	public static BookwormApp.Book genericParser(owned BookwormApp.Book aBook){
		//check if ebook is present at provided location
		if("false" == BookwormApp.Utils.fileOperations("EXISTS", "", aBook.getBookLocation(), "")){
			warning("EBook not found at provided location:"+aBook.getBookLocation());
			aBook.setIsBookParsed(false);
			aBook.setParsingIssue(BookwormApp.Constants.TEXT_FOR_EXTRACTION_ISSUE);
			return aBook;
		}
		//determine the extension of the ebook file
		string ebookFileName = (File.new_for_path(aBook.getBookLocation()).get_basename());
		if(ebookFileName.index_of(".") != -1){
			string fileExtension = ebookFileName.substring(ebookFileName.last_index_of(".")).up();
			debug ("extension found:"+fileExtension);
			//parse file based on extension found
			switch(fileExtension){
				case ".EPUB":
					aBook = BookwormApp.ePubReader.parseEPubBook(aBook);
					break;
				case ".PDF":
					aBook = BookwormApp.pdfReader.parsePDFBook(aBook);
					break;
				default:
					aBook.setIsBookParsed(false);
					aBook.setParsingIssue(BookwormApp.Constants.TEXT_FOR_FORMAT_NOT_SUPPORTED);
					break;
			}
		}
		return aBook;
	}
}
