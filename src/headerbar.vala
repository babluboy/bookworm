/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and creates the headerbar widget
* and all the widgets associated with the headerbar
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
public class BookwormApp.AppHeaderBar {
    public static Gtk.HeaderBar headerbar;
    private static Gtk.Window window;
    public static Gtk.SearchEntry headerSearchBar;
    public static Gtk.Button bookmark_inactive_button;
    public static Gtk.Button bookmark_active_button;
    public static BookwormApp.Settings settings;

    public static Gtk.HeaderBar create_headerbar() {
        info("[START] [FUNCTION:create_headerbar]");
        settings = BookwormApp.Settings.get_instance();
        BookwormApp.Bookworm.getAppInstance();
        headerbar = new Gtk.HeaderBar();

        headerbar.set_title(BookwormApp.Constants.TEXT_FOR_SUBTITLE_HEADERBAR);
        headerbar.set_show_close_button(true);
        headerbar.spacing = Constants.SPACING_WIDGETS;

        //add menu items to header bar - content list button
        BookwormApp.Bookworm.library_mode_button = new Granite.Widgets.ModeButton();
        BookwormApp.Bookworm.library_mode_button.append (BookwormApp.Bookworm.library_grid_button_image);
        BookwormApp.Bookworm.library_mode_button.append (BookwormApp.Bookworm.library_list_button_image);
        BookwormApp.Bookworm.library_mode_button.valign = Gtk.Align.CENTER;
        BookwormApp.Bookworm.library_mode_button.halign = Gtk.Align.START;
        BookwormApp.Bookworm.library_mode_button.set_size_request (60, -1);
        if(settings.library_view_mode == BookwormApp.Constants.BOOKWORM_UI_STATES[0]){
            BookwormApp.Bookworm.library_mode_button.set_active (0);
        }else{
            BookwormApp.Bookworm.library_mode_button.set_active (1);
        }

        BookwormApp.Bookworm.library_view_button = new Gtk.Button.with_label (BookwormApp.Constants.TEXT_FOR_LIBRARY_BUTTON);
        BookwormApp.Bookworm.library_view_button.get_style_context().add_class ("back-button");
        BookwormApp.Bookworm.library_view_button.valign = Gtk.Align.CENTER;
        BookwormApp.Bookworm.library_view_button.can_focus = false;
        BookwormApp.Bookworm.library_view_button.vexpand = false;

        BookwormApp.Bookworm.content_list_button = new Gtk.Button ();
        BookwormApp.Bookworm.content_list_button.set_image (BookwormApp.Bookworm.content_list_button_image);
        BookwormApp.Bookworm.content_list_button.set_valign(Gtk.Align.CENTER);
        BookwormApp.Bookworm.content_list_button.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_BOOK_INFO);

        BookwormApp.Bookworm.prefButton = new Gtk.Button();
        BookwormApp.Bookworm.prefButton.set_image (BookwormApp.Bookworm.menu_icon_text_large);
        BookwormApp.Bookworm.prefButton.set_valign(Gtk.Align.CENTER);
        BookwormApp.Bookworm.prefButton.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_READING_PREFERENCES);

        Gtk.Popover prefPopover = BookwormApp.PreferencesMenu.createPrefPopOver(BookwormApp.Bookworm.prefButton);

        Gtk.Image bookmark_inactive_button_image = new Gtk.Image ();
        bookmark_inactive_button_image.set_from_resource (Constants.BOOKMARK_INACTIVE_IMAGE_LOCATION);
        bookmark_inactive_button = new Gtk.Button ();
        bookmark_inactive_button.set_image (bookmark_inactive_button_image);
        bookmark_inactive_button.set_valign(Gtk.Align.CENTER);
        bookmark_inactive_button.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_BOOKMARKS_ACTIVATE);

        Gtk.Image bookmark_active_button_image = new Gtk.Image ();
        bookmark_active_button_image.set_from_resource (Constants.BOOKMARK_ACTIVE_IMAGE_LOCATION);
        bookmark_active_button = new Gtk.Button ();
        bookmark_active_button.set_image (bookmark_active_button_image);
        bookmark_active_button.set_valign(Gtk.Align.CENTER);
        bookmark_active_button.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_BOOKMARKS_DEACTIVATE);

        headerbar.add(BookwormApp.Bookworm.library_mode_button);
        headerbar.pack_start(BookwormApp.Bookworm.library_view_button);
        headerbar.pack_start(BookwormApp.Bookworm.content_list_button);
        headerbar.pack_start(BookwormApp.Bookworm.prefButton);
        headerbar.pack_start(bookmark_inactive_button);
        headerbar.pack_start(bookmark_active_button);

        //add menu items to header bar - Menu
        Gtk.MenuButton appMenu = new Gtk.MenuButton ();
        appMenu.set_image (BookwormApp.Bookworm.menu_icon);

        Gtk.Menu settingsMenu = new Gtk.Menu ();
        appMenu.popup = settingsMenu;

        Gtk.MenuItem prefferencesItem = new Gtk.MenuItem.with_label (BookwormApp.Constants.TEXT_FOR_PREF_MENU_PREFERENCES_ITEM);
        prefferencesItem.activate.connect (BookwormApp.AppDialog.createPreferencesDialog);
        settingsMenu.append (prefferencesItem);

        Gtk.MenuItem showAbout = new Gtk.MenuItem.with_label (BookwormApp.Constants.TEXT_FOR_PREF_MENU_ABOUT_ITEM);
        showAbout.activate.connect (ShowAboutDialog);
        settingsMenu.append (showAbout);
        settingsMenu.show_all ();
        headerbar.pack_end (appMenu);

        //Add a search entry to the header
        headerSearchBar = new Gtk.SearchEntry();
        headerSearchBar.set_max_width_chars(Constants.TEXT_FOR_HEADERBAR_LIBRARY_SEARCH.length);
        headerSearchBar.set_placeholder_text(Constants.TEXT_FOR_HEADERBAR_LIBRARY_SEARCH);
        headerbar.pack_end(headerSearchBar);

        //Set actions for HeaderBar search
        headerSearchBar.search_changed.connect (() => {
              //Call the filter only if the Library View Mode is active
              if(!(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[1] ||
                    BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[4])){
                    BookwormApp.Bookworm.libraryTreeModelFilter.refilter();
                    BookwormApp.AppWindow.library_grid.invalidate_filter ();
              }
        });

        headerSearchBar.activate.connect (() => {
              //Perform book search only if the Reading View or Info View is active
              if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[1] ||
                 BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[4]){
                    BookwormApp.Info.populateSearchResults();
                    //Set the mode to Info View Mode
                    BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[4];
                    BookwormApp.Bookworm.toggleUIState();
                    //Set the visible tab to search result tab
                    BookwormApp.Info.stack.set_visible_child (BookwormApp.Info.stack.get_child_by_name ("searchresults-list"));
              }
        });

        BookwormApp.Bookworm.library_view_button.clicked.connect (() => {
              //Set action of return to Library View if the current view is Reading View
              if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[1]){
                    //Get the current scroll position of the book and add it to the book object
                    (BookwormApp.Bookworm.libraryViewMap.get(
                                BookwormApp.Bookworm.locationOfEBookCurrentlyRead)
                    ).setBookScrollPos(BookwormApp.contentHandler.getScrollPos());
                    //Update header to remove title of book being read
                    headerbar.title = Constants.TEXT_FOR_SUBTITLE_HEADERBAR;
                    //set UI in library view mode
                    BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = settings.library_view_mode;
                    BookwormApp.Bookworm.toggleUIState();
              }
              //Set action of return to Reading View if the current view is Content View
              if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[4]){
                //set UI in library view mode
                BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[1];
                //Enable the flag which will scroll the page to the last read position
			    BookwormApp.Bookworm.isPageScrollRequired = true;
                BookwormApp.Book currentBookForContentList = BookwormApp.Bookworm.libraryViewMap.get(
                                            BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
                currentBookForContentList = BookwormApp.contentHandler.renderPage(
                                                BookwormApp.Bookworm.libraryViewMap.get(
                                                    BookwormApp.Bookworm.locationOfEBookCurrentlyRead),""
                                            );
                BookwormApp.Bookworm.libraryViewMap.set(
                                        BookwormApp.Bookworm.locationOfEBookCurrentlyRead, 
                                        currentBookForContentList
                );
                BookwormApp.Bookworm.toggleUIState();
              }
        });

        BookwormApp.Bookworm.content_list_button.clicked.connect (() => {
              BookwormApp.Info.createTableOfContents();
              //Set the mode to Content View Mode
              BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[4];
              //Get the current scroll position of the book and add it to the book object
              (BookwormApp.Bookworm.libraryViewMap.get(
                            BookwormApp.Bookworm.locationOfEBookCurrentlyRead)
              ).setBookScrollPos(BookwormApp.contentHandler.getScrollPos());
              BookwormApp.Bookworm.toggleUIState();
              //Open the Info section for the last viewed tab
              BookwormApp.Info.stack.set_visible_child (
                    BookwormApp.Info.stack.get_child_by_name (settings.current_info_tab)
              );
              //Refresh the tab if required
              if("bookmark-list"==settings.current_info_tab){
                    BookwormApp.Info.populateBookmarks();
              }
              if("annotations-list"==settings.current_info_tab){
                    BookwormApp.Info.populateAnnotations();
              }
              if("searchresults-list"==settings.current_info_tab){
                    if(BookwormApp.Info.firstSearchResultLinkButton != null){
                        //sets the focus on the first link
                        BookwormApp.Info.firstSearchResultLinkButton.grab_focus();
                    }
              }
        });

        BookwormApp.Bookworm.prefButton.clicked.connect (() => {
              //Get the current scroll position of the book and add it to the book object
              (BookwormApp.Bookworm.libraryViewMap.get(
                            BookwormApp.Bookworm.locationOfEBookCurrentlyRead)
              ).setBookScrollPos(BookwormApp.contentHandler.getScrollPos());
              prefPopover.set_visible (true);
              prefPopover.show_all();
        });

        bookmark_active_button.clicked.connect (() => {
            BookwormApp.contentHandler.handleBookMark("ACTIVE_CLICKED");
        });

        bookmark_inactive_button.clicked.connect (() => {
            BookwormApp.contentHandler.handleBookMark("INACTIVE_CLICKED");
        });

        BookwormApp.Bookworm.library_mode_button.mode_changed.connect ((widget) => {
            //disable the remove button, the same will be enabled if a book is choosen for removal
            BookwormApp.AppWindow.controlDeletionButton(false);
            if(widget == BookwormApp.Bookworm.library_grid_button_image){
                BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[0];
            }else{
                BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[5];
            }
            settings.library_view_mode = BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE;
            BookwormApp.Bookworm.toggleUIState();
        });
        info("[END] [FUNCTION:create_headerbar]");
        return headerbar;
    }

    public static Gtk.HeaderBar get_headerbar() {
        if(headerbar == null){
            create_headerbar();
        }
        return headerbar;
    }

    public static void ShowAboutDialog (){
        info("[START] [FUNCTION:ShowAboutDialog]");
        Gtk.AboutDialog aboutDialog = new Gtk.AboutDialog ();
        aboutDialog.set_destroy_with_parent (true);
	    aboutDialog.set_transient_for (window);
	    aboutDialog.set_modal (true);

        aboutDialog.set_attached_to(BookwormApp.Bookworm.window);
        aboutDialog.program_name = BookwormApp.Constants.program_name;
        aboutDialog.website = BookwormApp.Constants.TEXT_FOR_ABOUT_DIALOG_WEBSITE_URL;
        aboutDialog.website_label = BookwormApp.Constants.TEXT_FOR_ABOUT_DIALOG_WEBSITE;
        aboutDialog.logo_icon_name = BookwormApp.Constants.app_icon;
        aboutDialog.copyright = BookwormApp.Constants.bookworm_copyright;
        aboutDialog.version = BookwormApp.Constants.bookworm_version;
        aboutDialog.authors = BookwormApp.Constants.about_authors;
        aboutDialog.artists = BookwormApp.Constants.about_artists;
        aboutDialog.comments = BookwormApp.Constants.about_comments;
        aboutDialog.license = null;
        aboutDialog.license_type = BookwormApp.Constants.about_license_type;
        aboutDialog.translator_credits = BookwormApp.Constants.translator_credits;
        
        aboutDialog.present ();
        aboutDialog.response.connect((response_id) => {
            aboutDialog.destroy ();
        });
        info("[END] [FUNCTION:ShowAboutDialog]");
    }
}
