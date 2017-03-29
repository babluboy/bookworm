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

public class BookwormApp.Bookworm:Granite.Application {
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
	public static Gtk.Window window;
	public static Gtk.Box bookWormUIBox;
	public static Granite.Widgets.Welcome welcomeWidget;
	public static Gtk.Button library_view_button;
	public static Gtk.Button content_list_button;
	public static Gtk.Box textSizeBox;
	public static Gdk.Pixbuf bookSelectionPix;
	public static Gdk.Pixbuf bookSelectedPix;
	public static Gtk.Image bookSelectionImage;

	public static string BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[0];
	public static Gee.HashMap<string, BookwormApp.Book> libraryViewMap = new Gee.HashMap<string, BookwormApp.Book>();
	public static string locationOfEBookCurrentlyRead = "";
	public static int countBooksAddedIntoLibraryRow = 0;
	public static string[] pathsOfBooksToBeAdded;
	public static int noOfBooksAddedFromCommand = 0;
	public static bool isBookBeingAddedToLibrary = false;

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

	//Handle action for close of the InfoBar
	public static void on_info_bar_closed(){
      BookwormApp.AppWindow.infobar.hide();
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
				BookwormApp.AppWindow.bookAdditionBar.set_pulse_step ((noOfBooksAddedFromCommand/(pathsOfBooksToBeAdded.length-1)));
				BookwormApp.AppWindow.bookAdditionBar.pulse();
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

	public static void removeSelectedBooksFromLibrary(){
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
		BookwormApp.AppWindow.library_grid.show_all();
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

	public static void updateLibraryView(owned BookwormApp.Book aBook){
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
		BookwormApp.AppWindow.library_grid.add (aEventBox);

		//set gtk objects into Book objects
		aBook.setCoverImage (aCoverImage);
		aBook.setEventBox(aEventBox);
		aBook.setOverlayImage(aOverlayImage);

		//set the view mode to library view
		BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[0];
		BookwormApp.AppWindow.library_grid.show_all();
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

	public static void updateLibraryViewForSelectionMode(owned BookwormApp.Book? lBook){
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
		BookwormApp.AppWindow.library_grid.show_all();
		toggleUIState();
	}

	public static void readSelectedBook(owned BookwormApp.Book aBook){
		//Extract and Parse the eBook (this will overwrite the contents already extracted)
		aBook = BookwormApp.ePubReader.parseEPubBook(aBook);
		//check if ebook was parsed sucessfully
		if(!aBook.getIsBookParsed()){
			StringBuilder warningMessage = new StringBuilder("");
				warningMessage.append(BookwormApp.Constants.TEXT_FOR_RENDERING_ISSUE)
											.append(" : ")
											.append(aBook.getBookLocation());
			BookwormApp.AppWindow.infobarLabel.set_text(warningMessage.str);
			BookwormApp.AppWindow.infobar.set_message_type (MessageType.WARNING);
			BookwormApp.AppWindow.infobar.show();
		}else{
			aBook.setBookLastModificationDate((new DateTime.now_utc().to_unix()).to_string());
			aBook.setWasBookOpened(true);
			//render the contents of the current page of book
			aBook = renderPage(aBook, "");
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
			content_list_button.set_visible(false);
			library_view_button.set_visible(false);
			BookwormApp.AppWindow.bookLibrary_ui_box.set_visible(true);
			BookwormApp.AppWindow.bookReading_ui_box.set_visible(false);
			BookwormApp.Info.info_box.set_visible(false);
			textSizeBox.set_visible(false);
			if(!isBookBeingAddedToLibrary)
				BookwormApp.AppWindow.bookAdditionBar.hide();
		}
		//Reading Mode
		if(BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[1]){
			//UI for Reading View
			content_list_button.set_visible(true);
			library_view_button.set_visible(true);
			library_view_button.set_label(BookwormApp.Constants.TEXT_FOR_LIBRARY_BUTTON);
			BookwormApp.AppWindow.bookLibrary_ui_box.set_visible(false);
			BookwormApp.AppWindow.bookReading_ui_box.set_visible(true);
			BookwormApp.Info.info_box.set_visible(false);
			textSizeBox.set_visible(true);
			BookwormApp.AppWindow.bookAdditionBar.hide();
		}
		//Book Meta Data / Content View Mode
		if(BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[4]){
			//UI for Reading View
			BookwormApp.Info.info_box.show_all();
			content_list_button.set_visible(true);
			library_view_button.set_visible(true);
			library_view_button.set_label(BookwormApp.Constants.TEXT_FOR_RESUME_BUTTON);
			BookwormApp.AppWindow.bookLibrary_ui_box.set_visible(false);
			BookwormApp.AppWindow.bookReading_ui_box.set_visible(false);
			BookwormApp.Info.info_box.set_visible(true);
			BookwormApp.Info.stack.set_visible_child_name ("content-list");
			textSizeBox.set_visible(false);
			BookwormApp.AppWindow.bookAdditionBar.hide();
		}
	}

	public async void saveBooksState (){
			foreach (var book in libraryViewMap.values){
				//Update the book details to the database if it was opened in this session
				if(((BookwormApp.Book)book).getWasBookOpened()){
					BookwormApp.DB.updateBookToDataBase((BookwormApp.Book)book);
					debug("Completed saving the book data into DB");
				}
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

	public static BookwormApp.Book renderPage (owned BookwormApp.Book aBook, string direction){
		int currentContentLocation = aBook.getBookPageNumber();;
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

			default://This is for opening the current page of the book
				//No change of page number required
				break;
		}
		//render the content on webview
    BookwormApp.AppWindow.aWebView.load_html(BookwormApp.ePubReader.provideContent(aBook,currentContentLocation), BookwormApp.Constants.PREFIX_FOR_FILE_URL);
    //set the focus to the webview to capture keypress events
    BookwormApp.AppWindow.aWebView.grab_focus();
		return aBook;
	}
}
