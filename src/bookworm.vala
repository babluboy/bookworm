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
	private static bool command_line_option_discover = false;
	private static OptionEntry[] options;

	public StringBuilder spawn_async_with_pipes_output = new StringBuilder("");

	public static BookwormApp.Settings settings;
	public static Gtk.ApplicationWindow window;
	public static Gtk.IconTheme default_theme;
	public static CssProvider cssProvider;
	public static Gtk.Box bookWormUIBox;
	public static Granite.Widgets.Welcome welcomeWidget;
	public static Granite.Widgets.ModeButton library_mode_button;
	public static Gtk.TreeModelFilter libraryTreeModelFilter;
	public static Gtk.Button library_view_button;
	public static Gtk.Button content_list_button;
	public static Gtk.Button prefButton;
	public static Gdk.Pixbuf bookSelectionPix;
	public static Gdk.Pixbuf bookSelectedPix;
	public static Gdk.Pixbuf image_selection_option_small;
	public static Gdk.Pixbuf image_selection_checked_small;
	public static Gdk.Pixbuf image_selection_transparent_small;
	public static Gdk.Pixbuf image_selection_scaled;
	public static Gdk.Pixbuf image_rating_1;
	public static Gdk.Pixbuf image_rating_2;
	public static Gdk.Pixbuf image_rating_3;
	public static Gdk.Pixbuf image_rating_4;
	public static Gdk.Pixbuf image_rating_5;
	public static Gtk.Image select_book_image;
	public static Gtk.Image add_book_image;
	public static Gtk.Image remove_book_image;
	public static Gtk.Image updateImageIcon;
	public static Gtk.Image add_scan_directory_image;
	public static Gtk.Image remove_scan_directory_image;
	public static Gtk.Image library_list_button_image;
	public static Gtk.Image library_grid_button_image;
	public static Gtk.Image content_list_button_image;
	public static Gtk.Image menu_icon_text_large;
	public static Gtk.Image menu_icon;
	public static Gtk.Image pref_menu_icon_text_large;
	public static Gtk.Image pref_menu_icon_text_small;
	public static Gtk.Image back_button_image;
	public static Gtk.Image forward_button_image;

	public static string BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[0];
	public static Gee.HashMap<string, BookwormApp.Book> libraryViewMap = new Gee.HashMap<string, BookwormApp.Book>();
	public static string locationOfEBookCurrentlyRead = "";
	public static string[] pathsOfBooksToBeAdded;
	public static int noOfBooksAddedFromCommand = 0;
	public static bool isBookBeingAddedToLibrary = false;
	public static ArrayList<string> profileColourList = new ArrayList<string> ();
	public static bool isPageScrollRequired = false;
	public static StringBuilder pathsOfBooksInLibraryOnLoadStr = new StringBuilder("");

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
		options[2] = { "discover", 0, 0, OptionArg.NONE, ref command_line_option_discover, _("Automatically add new books from watched folders"), null };
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
		}else if(command_line_option_discover){
			BookwormApp.BackgroundTasks.performTasks();
			return 0;
		}else{
			activate();
			return 0;
		}
	}

	public override void activate() {
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
			cssProvider = new Gtk.CssProvider();
			loadCSSProvider(cssProvider);
			//load images/icons
			loadImages();
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
		//check if any books needed to be added/opened - if eBook(s) were opened from File Explorer using Bookworm
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
			//Update the library view with books - this returns control back immediately
			BookwormApp.Library.addBooksToLibrary ();
		}
		//Perform post start up actions
		BookwormApp.contentHandler.performStartUpActions();
		toggleUIState();
		debug("Ending activate method");
	}

	public override void open (File[] files, string hint) {

	}

	public void loadImages(){
		try{
			image_selection_option_small = new Gdk.Pixbuf.from_file (BookwormApp.Constants.SELECTION_OPTION_IMAGE_SMALL_LOCATION);
			image_selection_checked_small = new Gdk.Pixbuf.from_file (BookwormApp.Constants.SELECTION_CHECKED_IMAGE_SMALL_LOCATION);
			image_selection_transparent_small = new Gdk.Pixbuf.from_file (BookwormApp.Constants.SELECTION_CHECKED_IMAGE_SMALL_LOCATION);
			image_selection_transparent_small.fill(0x00000000);
			image_rating_1 = new Gdk.Pixbuf.from_file (BookwormApp.Constants.RATING_1_IMAGE_LOCATION);
		  image_rating_2 = new Gdk.Pixbuf.from_file (BookwormApp.Constants.RATING_2_IMAGE_LOCATION);
		  image_rating_3 = new Gdk.Pixbuf.from_file (BookwormApp.Constants.RATING_3_IMAGE_LOCATION);
		  image_rating_4 = new Gdk.Pixbuf.from_file (BookwormApp.Constants.RATING_4_IMAGE_LOCATION);
		  image_rating_5 = new Gdk.Pixbuf.from_file (BookwormApp.Constants.RATING_5_IMAGE_LOCATION);
			
			if (Gtk.IconTheme.get_default ().has_icon ("object-select-symbolic")) {
	      select_book_image = new Gtk.Image.from_icon_name ("object-select-symbolic", Gtk.IconSize.MENU);
	    }else{
				select_book_image = new Gtk.Image.from_file (BookwormApp.Constants.SELECT_BOOK_ICON_IMAGE_LOCATION);
			}

			if (Gtk.IconTheme.get_default ().has_icon ("list-add-symbolic")) {
	      add_book_image = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU);
	    }else{
				add_book_image = new Gtk.Image.from_file (BookwormApp.Constants.ADD_BOOK_ICON_IMAGE_LOCATION);
			}

			if (Gtk.IconTheme.get_default ().has_icon ("list-remove-symbolic")) {
	      remove_book_image = new Gtk.Image.from_icon_name ("list-remove-symbolic", Gtk.IconSize.MENU);
	    }else{
				remove_book_image = new Gtk.Image.from_file (BookwormApp.Constants.REMOVE_BOOK_ICON_IMAGE_LOCATION);
			}

			if (Gtk.IconTheme.get_default ().has_icon ("list-add-symbolic")) {
	      add_scan_directory_image = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU);
	    }else{
				add_scan_directory_image = new Gtk.Image.from_file (BookwormApp.Constants.ADD_BOOK_ICON_IMAGE_LOCATION);
			}

			if (Gtk.IconTheme.get_default ().has_icon ("list-remove-symbolic")) {
	      remove_scan_directory_image = new Gtk.Image.from_icon_name ("list-remove-symbolic", Gtk.IconSize.MENU);
	    }else{
				remove_scan_directory_image = new Gtk.Image.from_file (BookwormApp.Constants.REMOVE_BOOK_ICON_IMAGE_LOCATION);
			}

			if (Gtk.IconTheme.get_default ().has_icon ("view-list-symbolic")) {
	      library_list_button_image = new Gtk.Image.from_icon_name ("view-list-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
	    }else{
				library_list_button_image = new Gtk.Image.from_pixbuf (new Gdk.Pixbuf.from_file_at_scale (BookwormApp.Constants.LIBRARY_VIEW_LIST_IMAGE_LOCATION, 16, 16, true));
			}

			if (Gtk.IconTheme.get_default ().has_icon ("view-grid-symbolic")) {
	      library_grid_button_image = new Gtk.Image.from_icon_name ("view-grid-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
	    }else{
				library_grid_button_image = new Gtk.Image.from_pixbuf (new Gdk.Pixbuf.from_file_at_scale (BookwormApp.Constants.LIBRARY_VIEW_GRID_IMAGE_LOCATION, 16, 16, true));
			}

			if (Gtk.IconTheme.get_default ().has_icon ("help-info-symbolic")) {
	      content_list_button_image = new Gtk.Image.from_icon_name ("help-info-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
	    }else{
				content_list_button_image = new Gtk.Image.from_pixbuf (new Gdk.Pixbuf.from_file_at_scale (BookwormApp.Constants.BOOK_INFO_IMAGE_LOCATION, 24, 24, true));
			}

			if (Gtk.IconTheme.get_default ().has_icon ("format-text-larger-symbolic")) {
	      menu_icon_text_large = new Gtk.Image.from_icon_name ("format-text-larger-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
	    }else{
				menu_icon_text_large = new Gtk.Image.from_pixbuf (new Gdk.Pixbuf.from_file_at_scale (BookwormApp.Constants.TEXT_LARGER_IMAGE_ICON_LOCATION, 24, 24, true));
			}

			if (Gtk.IconTheme.get_default ().has_icon ("open-menu")) {
	      menu_icon = new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR);
	    }else{
				menu_icon = new Gtk.Image.from_pixbuf (new Gdk.Pixbuf.from_file_at_scale (BookwormApp.Constants.HEADERBAR_PROPERTIES_IMAGE_LOCATION, 24, 24, true));
			}

			if (Gtk.IconTheme.get_default ().has_icon ("format-text-larger-symbolic")) {
	      pref_menu_icon_text_large = new Gtk.Image.from_icon_name ("format-text-larger-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
	    }else{
				pref_menu_icon_text_large = new Gtk.Image.from_pixbuf (new Gdk.Pixbuf.from_file_at_scale (BookwormApp.Constants.TEXT_LARGER_IMAGE_ICON_LOCATION, 24, 24, true));
			}

			if (Gtk.IconTheme.get_default ().has_icon ("format-text-smaller-symbolic")) {
	      pref_menu_icon_text_small = new Gtk.Image.from_icon_name ("format-text-smaller-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
	    }else{
				pref_menu_icon_text_small = new Gtk.Image.from_pixbuf (new Gdk.Pixbuf.from_file_at_scale (BookwormApp.Constants.TEXT_SMALLER_IMAGE_ICON_LOCATION, 24, 24, true));
			}

			if (Gtk.IconTheme.get_default ().has_icon ("go-previous-symbolic")) {
	      back_button_image = new Gtk.Image.from_icon_name ("go-previous-symbolic", Gtk.IconSize.MENU);
	    }else{
				back_button_image = new Gtk.Image.from_file (BookwormApp.Constants.PREV_PAGE_ICON_IMAGE_LOCATION);
			}

			if (Gtk.IconTheme.get_default ().has_icon ("go-next-symbolic")) {
	      forward_button_image = new Gtk.Image.from_icon_name ("go-next-symbolic", Gtk.IconSize.MENU);
	    }else{
				forward_button_image = new Gtk.Image.from_file (BookwormApp.Constants.NEXT_PAGE_ICON_IMAGE_LOCATION);
			}
		}catch(GLib.Error e){
			warning("Image could not be loaded. Error:"+e.message);
		}
	}

	public static void loadCSSProvider(Gtk.CssProvider cssProvider){
		try{
			//cssProvider.load_from_path(BookwormApp.Constants.CSS_LOCATION);
			string[] profileColorList = settings.list_of_profile_colors.split (",");
			string dynamicCSSContent = BookwormApp.Constants.DYNAMIC_CSS_CONTENT
																					 .replace("<profile_1_color>",profileColorList[0])
																					 .replace("<profile_1_bgcolor>",profileColorList[1])
																					 .replace("<profile_2_color>",profileColorList[2])
																					 .replace("<profile_2_bgcolor>",profileColorList[3])
																					 .replace("<profile_3_color>",profileColorList[4])
																					 .replace("<profile_3_bgcolor>",profileColorList[5]);
			cssProvider.load_from_data(dynamicCSSContent, dynamicCSSContent.length);
		}catch(GLib.Error e){
			warning("Stylesheet could not be loaded. Error:"+e.message);
		}
		Gtk.StyleContext.add_provider_for_screen(
											Gdk.Screen.get_default(),
											cssProvider,
											Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
										 );
	}

	public void loadBookwormState(){
		//check and create required directory structure
    BookwormApp.Utils.fileOperations("CREATEDIR", BookwormApp.Constants.EBOOK_EXTRACTION_LOCATION, "", "");
		BookwormApp.Utils.fileOperations("CREATEDIR", bookworm_config_path, "", "");
		BookwormApp.Utils.fileOperations("CREATEDIR", bookworm_config_path+"/covers/", "", "");
		BookwormApp.Utils.fileOperations("CREATEDIR", bookworm_config_path+"/books/", "", "");
		//check last state and turn on dark theme
		if(BookwormApp.Bookworm.settings.is_dark_theme_enabled){
			Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
		}
		//check if the database exists otherwise create database and required tables
		bool isDBPresent = BookwormApp.DB.initializeBookWormDB(bookworm_config_path);
		//set the library view
		BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = settings.library_view_mode;
		//Fetch details of Books from the database
		BookwormApp.Library.listOfBooksInLibraryOnLoad = BookwormApp.DB.getBooksFromDB();
		//Update the library view
		BookwormApp.Library.updateLibraryViewFromDB();
	}

	public async void closeBookWorm (){
			//If Bookworm was closed while in Reading mode - save book details for subsequent read
			if(BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[1]) {
				//Save the page scroll position of the book being read
				(libraryViewMap.get(locationOfEBookCurrentlyRead)).setBookScrollPos(BookwormApp.contentHandler.getScrollPos());
				//Save the path to the book being read
				settings.book_being_read = locationOfEBookCurrentlyRead;
			}else{
				//Bookworm was not in reading view during close - remove path of book read last
				settings.book_being_read = "";
			}
			//release the control so that the window is closed
			Idle.add (closeBookWorm.callback);
			yield;
			//Update the book details to the database if it was opened in this session
			foreach (var book in libraryViewMap.values){
				if(((BookwormApp.Book)book).getWasBookOpened()){
					BookwormApp.DB.updateBookToDataBase((BookwormApp.Book)book);
					debug("Completed saving the book data into DB");
				}
			}
			//Check and create a task scheduler cron job if not already present
			BookwormApp.BackgroundTasks.taskScheduler();
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

	public static void readSelectedBook(owned BookwormApp.Book aBook){
		//Handle the case when the page number of the book is not set
    if(aBook.getBookPageNumber() == -1){
			aBook.setBookPageNumber(0);
		}else{
			//This book was previously being read, so it should be opened at the last reading position
			//Enable the flag which will scroll the page to the last read position
			isPageScrollRequired = true;
		}
		//Handle the case when the page number of the book is outside limits
    if(aBook.getBookPageNumber() >= aBook.getBookContentList().size){
			aBook.setBookPageNumber(aBook.getBookContentList().size - 1);
		}
		//check if the extracted contents for the book exists
		if(BookwormApp.Bookworm.settings.is_local_storage_enabled &&
			"true" == BookwormApp.Utils.fileOperations("DIR_EXISTS", aBook.getBookExtractionLocation(), "", "") &&
			aBook.getBookContentList() != null && aBook.getBookContentList().size > 0 &&
			aBook.getBookContentList().size >= aBook.getBookPageNumber() &&
			"true" == BookwormApp.Utils.fileOperations("EXISTS", BookwormApp.Utils.decodeHTMLChars(aBook.getBookContentList().get(aBook.getBookPageNumber())), "", "")
		){
			//extraction of book not required
			aBook.setIsBookParsed(true);
		}else{
			//Extract and Parse the eBook (this will overwrite the contents already extracted)
			aBook = genericParser(aBook);
			//If ebook was not parsed sucessfully, show the warning info banner message
			if(!aBook.getIsBookParsed()){
				BookwormApp.AppWindow.showInfoBar(aBook, MessageType.WARNING);
			}
		}
		//progress in opening the book for reading if it has been parsed sucessfully
		if(aBook.getIsBookParsed()){
			//update book to mark it has been opened in this session
			aBook.setBookLastModificationDate((new DateTime.now_utc().to_unix()).to_string());
			aBook.setWasBookOpened(true);
			//update book details to libraryView Map
			libraryViewMap.set(aBook.getBookLocation(), aBook);
			locationOfEBookCurrentlyRead = aBook.getBookLocation();
			//Update header title
			BookwormApp.AppHeaderBar.get_headerbar().title = aBook.getBookTitle();
			//change the application view to Book Reading mode
			BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[1];
			toggleUIState();
			//reset the contents of the search entry
			BookwormApp.Info.searchresults_scroll.get_child().destroy();
			//set the max value and the current value of the page slider
			BookwormApp.AppWindow.pageAdjustment.set_upper(aBook.getBookContentList().size);
			BookwormApp.AppWindow.pageAdjustment.set_value(aBook.getBookPageNumber());
			//render the contents of the current page of book
			aBook = renderPage(aBook, "");
		}
	}

	public static void toggleUIState(){
		debug("Initited toggleUIState with BOOKWORM_CURRENT_STATE:"+BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE);
		//hide the inforbar if there is no text in it
		if(BookwormApp.AppWindow.infobarLabel.get_text().length < 1){
			BookwormApp.AppWindow.infobar.hide();
		}

		//Set-up UI for Library View
		//Show the grid view or the list view based on state
    if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[0] ||
			 BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[2] ||
			 BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[3])
		{
      BookwormApp.AppWindow.library_list_scroll.set_visible(false);
			BookwormApp.AppWindow.library_grid_scroll.set_visible(true);
			BookwormApp.AppWindow.library_grid.show_all();
    }
		if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[5] ||
			 BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[6] ||
			 BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[7])
		{
      BookwormApp.AppWindow.library_grid_scroll.set_visible(false);
			BookwormApp.AppWindow.library_list_scroll.set_visible(true);
			BookwormApp.AppWindow.library_table_treeview.show_all();
		}

		if(BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[0] ||
			 BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[2] ||
			 BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[3] ||
			 BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[5]
			){
			BookwormApp.AppHeaderBar.headerSearchBar.set_placeholder_text(BookwormApp.Constants.TEXT_FOR_HEADERBAR_LIBRARY_SEARCH);
			library_mode_button.set_visible(true);
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
		//Set-up UI for Reading Mode
		if(BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[1]){
			//UI for Reading View
			BookwormApp.AppHeaderBar.headerSearchBar.set_placeholder_text(BookwormApp.Constants.TEXT_FOR_HEADERBAR_BOOK_SEARCH);
			library_mode_button.set_visible(false);
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
		//Set-up UI for Book Meta Data / Content View Mode
		if(BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[4]){
			//UI for Reading View
			BookwormApp.AppHeaderBar.headerSearchBar.set_placeholder_text(BookwormApp.Constants.TEXT_FOR_HEADERBAR_LIBRARY_SEARCH);
			BookwormApp.Info.info_box.show_all();
			library_mode_button.set_visible(false);
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
		//set the current value of the page slider
		BookwormApp.AppWindow.pageAdjustment.set_value(currentContentLocation+1);
		return aBook;
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
			//parse file based on extension found
			try{
				switch(fileExtension){
					case ".EPUB":
						aBook = BookwormApp.ePubReader.parseEPubBook(aBook);
						break;
					case ".PDF":
						aBook = BookwormApp.pdfReader.parsePDFBook(aBook);
						break;
					case ".CBR":
						aBook = BookwormApp.comicsReader.parseComicsBook(aBook, fileExtension);
						break;
					case ".CBZ":
						aBook = BookwormApp.comicsReader.parseComicsBook(aBook, fileExtension);
						break;
					case ".MOBI":
						aBook = BookwormApp.mobiReader.parseMobiBook(aBook);
						break;
					case ".PRC":
						aBook = BookwormApp.mobiReader.parseMobiBook(aBook);
						break;
					default:
						aBook.setIsBookParsed(false);
						aBook.setParsingIssue(BookwormApp.Constants.TEXT_FOR_FORMAT_NOT_SUPPORTED);
						break;
				}
			}catch(GLib.Error e){
				info ("Error while parsing book: %s\n", e.message);
				aBook.setIsBookParsed(false);
				aBook.setParsingIssue(BookwormApp.Constants.TEXT_FOR_PARSING_ISSUE);
			}
		}
		return aBook;
	}

}
