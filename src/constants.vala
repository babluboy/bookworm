/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and is used as the single place for
* holding all translatable strings and app constants
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

namespace BookwormApp.Constants {
	public const string bookworm_id = "com.github.babluboy.bookworm";
	public const string bookworm_version = "1.0.0";
	public const string program_name = "Bookworm";
	public const string app_years = "2017-2018";
	public const string app_icon = "com.github.babluboy.bookworm";
	public const string[] about_authors = {"Siddhartha Das <bablu.boy@gmail.com>", null};
	public const string[] about_artists = {"Micah Ilbery <micah.ilbery@protonmail.com>", null};
	public const string bookworm_copyright = "Copyright © 2017-2018 Siddhartha Das (bablu.boy@gmail.com)";
	public const string about_comments = _("An eBook Reader");
	public const Gtk.License about_license_type = Gtk.License.GPL_3_0;
	public const string translator_credits = _("Weblate Translators");
	public const string main_url = "https://babluboy.github.io/bookworm";
	public const string bug_url = "https://github.com/babluboy/bookworm/issues";
	public const string help_url = "https://github.com/babluboy/bookworm/wiki";
	public const string translate_url = "https://hosted.weblate.org/projects/bookworm/bookworm/";

	public const string TEXT_FOR_ABOUT_DIALOG_WEBSITE = _("Website | Translation | Bug Tracker");
	public const string TEXT_FOR_ABOUT_DIALOG_WEBSITE_URL = "https://babluboy.github.io/bookworm";
	public const string TEXT_FOR_NOT_AVAILABLE = _("Not Available");
	public const string TEXT_FOR_SUBTITLE_HEADERBAR = _("eBook Reader");
	public const string TEXT_FOR_HEADERBAR_BOOK_SEARCH = _("Search this book…");
	public const string TEXT_FOR_HEADERBAR_LIBRARY_SEARCH = _("Search by Title, Author and Tags");
	public const string TEXT_FOR_WELCOME_MESSAGE_TITLE = _("Looks like Bookworm has no books.");
	public const string TEXT_FOR_WELCOME_MESSAGE_SUBTITLE = _("Build your library by adding eBooks");
	public const string TEXT_FOR_WELCOME_OPENDIR_MESSAGE = _("Select an eBook to read");
	public const string TEXT_FOR_EXTRACTION_ISSUE = _("Problem in extracting contents of book. Ensure there is a valid eBook file here: ");
	public const string TEXT_FOR_MIMETYPE_ISSUE = _("Invalid MIME-type detected. Check format for this eBook: ");
	public const string TEXT_FOR_CONTENT_ISSUE = _("Invalid content found. Ensure there is a valid eBook file here: ");
	public const string TEXT_FOR_PARSING_ISSUE = _("eBook could not be parsed. Ensure there is a valid eBook file here: ");
	public const string TEXT_FOR_FORMAT_NOT_SUPPORTED = _("Bookworm does not support the format of the file found here: ");
	public const string TEXT_FOR_CONTENT_NOT_FOUND_ISSUE = _("Requested content could not be fetched. Please remove and add the eBook file found here: ");
	public const string TEXT_FOR_LIBRARY_BUTTON = _("Library");
	public const string TEXT_FOR_RESUME_BUTTON = _("Resume");
	public const string TEXT_FOR_INFO_TAB_CONTENTS = _("Contents");
	public const string TEXT_FOR_INFO_TAB_CONTENT_PREFIX = _("Content #");
	public const string TEXT_FOR_INFO_TAB_BOOKMARKS = _("Bookmarks");
	public const string TEXT_FOR_BOOKMARKS = _("Bookmark #NNN for Section PPP");
	public const string TEXT_FOR_BOOKMARKS_FOUND = _("Click on a link to jump to bookmarked section");
	public const string TEXT_FOR_BOOKMARKS_NOT_FOUND = _("No bookmarks set in BBB, click the bookworm icon on the header bar to boomark the page");
	public const string TEXT_FOR_INFO_TAB_SEARCHRESULTS = _("Search Results");
	public const string TEXT_FOR_INFO_TAB_ANNOTATIONS = _("Annotations");
	public const string TEXT_FOR_ANNOTATION_TAG = _("Annotation Tags");
	public const string TEXT_FOR_ANNOTATION_TAG_ENTRY = _("Comma seperated tags for this annotation");
	public const string TEXT_FOR_ANNOTATION = _("Add annotation for: ");
	public const string TEXT_FOR_ANNOTATIONS_FOUND = _("Click on a link to jump to an annotated section");
	public const string TEXT_FOR_ANNOTATIONS_NOT_FOUND = _("No annotations set in BBB, right click the page of a book and choose annotation from the context menu to add annotations");
	public const string TEXT_FOR_SEARCH_RESULTS_PROCESSING = _("Searching for '$$$' in &&&:");
	public const string TEXT_FOR_SEARCH_RESULTS_FOUND = _("Found the following matches for '$$$' in &&&:");
	public const string TEXT_FOR_SEARCH_RESULTS_NOT_FOUND = _("No matches found for '$$$' in &&&");
	public const string TEXT_FOR_BOOK_CONTEXTMENU_HEADER = _("Edit Info for");
	public const string TEXT_FOR_BOOK_CONTEXTMENU_UPDATE_COVER_IMAGE = _("Update Cover Image");
	public const string TEXT_FOR_BOOK_CONTEXTMENU_UPDATE_TITLE = _("Update Title");
	public const string TEXT_FOR_BOOK_CONTEXTMENU_UPDATE_TAGS = _("Update Tags");
	public const string TEXT_FOR_BOOK_CONTEXTMENU_UPDATE_AUTHOR = _("Update Author");
	public const string TEXT_FOR_BOOK_CONTEXTMENU_UPDATE_COVER = _("Update Cover Image");
	public const string TEXT_FOR_PAGE_CONTEXTMENU_FULL_SCREEN_ENTRY = _("Enter full screen view (F11)");
	public const string TEXT_FOR_PAGE_CONTEXTMENU_FULL_SCREEN_EXIT = _("Exit full screen view (Esc)");
	public const string TEXT_FOR_PAGE_CONTEXTMENU_WORD_MEANING = _("Check Word Meaning");
	public const string TEXT_FOR_PAGE_CONTEXTMENU_ANNOTATE_SELECTION = _("Annotate selected text");
	public const string TEXT_FOR_FILE_CHOOSER_FILTER_BOOKS = _("Books");
	public const string TEXT_FOR_FILE_CHOOSER_FILTER_IMAGES = _("Images");
	public const string TEXT_FOR_FILE_CHOOSER_FILTER_ALL_FILES = _("All Files");
	public const string TEXT_FOR_LIST_VIEW_COLUMN_NAME_TITLE = _("Title");
	public const string TEXT_FOR_LIST_VIEW_COLUMN_NAME_AUTHOR = _("Author");
	public const string TEXT_FOR_LIST_VIEW_COLUMN_NAME_MODIFIED_DATE = _("Last Opened");
	public const string TEXT_FOR_LIST_VIEW_COLUMN_NAME_RATING = _("Rating");
	public const string TEXT_FOR_LIST_VIEW_COLUMN_NAME_TAGS = _("Tags");
	public const string TEXT_FOR_TIME_TODAY = _("Today");
	public const string TEXT_FOR_TIME_YESTERDAY = _("Yesterday");
	public const string TEXT_FOR_TIME_DAYS = _("Days");
	public const string TEXT_BOOK_DISCOVERY_TOAST = _("Discovery of books will be started when Bookworm is closed");

	public const string TOOLTIP_TEXT_FOR_ADD_BOOK = _("Add books to library");
	public const string TOOLTIP_TEXT_FOR_REMOVE_BOOK = _("Remove selected books from library (eBook file will not be deleted)");
	public const string TOOLTIP_TEXT_FOR_SELECT_BOOK = _("Select one or more books in library");
	public const string TOOLTIP_TEXT_FOR_BOOK_INFO = _("See Table of Contents, Bookmarks and Search Results");
	public const string TOOLTIP_TEXT_FOR_READING_PREFERENCES = _("Reading preferences");
	public const string TOOLTIP_TEXT_FOR_BOOKMARKS_ACTIVATE = _("Click to bookmark this page");
	public const string TOOLTIP_TEXT_FOR_BOOKMARKS_DEACTIVATE = _("Click to remove this bookmark");
	public const string TOOLTIP_TEXT_FOR_FONT_SIZE_INCREASE = _("Increase font size (Ctrl + Shift + '+')");
	public const string TOOLTIP_TEXT_FOR_FONT_SIZE_DECREASE = _("Decrease font size (Ctrl + '-')");
	public const string TOOLTIP_TEXT_FOR_LINE_WIDTH_INCREASE = _("Increase line width");
	public const string TOOLTIP_TEXT_FOR_LINE_WIDTH_DECREASE = _("Decrease line width");
	public const string TOOLTIP_TEXT_FOR_LINE_HEIGHT_INCREASE = _("Increase line spacing");
	public const string TOOLTIP_TEXT_FOR_LINE_HEIGHT_DECREASE = _("Decrease line spacing");
	public const string TOOLTIP_TEXT_FOR_UPDATING_COVER_IMAGE = _("Update cover image");
	public const string TOOLTIP_TEXT_FOR_PROFILE = _("Apply theme for this colour profile");
	public const string TOOLTIP_TEXT_FOR_PAGE_CONTEXTMENU_FULL_SCREEN_ENTRY = _("Enter full screen view and Esc key to undo");
	public const string TOOLTIP_TEXT_FOR_PAGE_CONTEXTMENU_FULL_SCREEN_EXIT = _("Enter full screen view and Esc key to undo");
	public const string TOOLTIP_TEXT_FOR_ADD_DIRECTORY = _("Add folder to scan for books");
	public const string TOOLTIP_TEXT_FOR_REMOVE_DIRECTORY = _("Remove displayed folder from book scan");
	public const string TOOLTIP_TEXT_FOR_PAGE_CONTEXTMENU_ANNOTATE_SELECTION = _("Add annotation to selected text");

	public const string TEXT_FOR_PREFERENCES_DIALOG_TITLE = _("Preferences");
	public const string TEXT_FOR_PREFERENCES_COLOUR_SCHEME = _("Turn on Dark Mode");
	public const string TEXT_FOR_PREFERENCES_LOCAL_STORAGE = _("Enable cache (opens books faster)");
	public const string TEXT_FOR_PREFERENCES_SKIP_LIBRARY = _("Always show library on startup");
	public const string TEXT_FOR_PREFERENCES_TWO_PAGE = _("Enable two page reading");
	public const string TEXT_FOR_PREFERENCES_FONT = _("Select Font");
	public const string TEXT_FOR_PROFILE_CUSTOMIZATION = _("Customize reading profile");
	public const string TEXT_FOR_PROFILE_CUSTOMIZATION_FONT_COLOR = _("Text");
	public const string TEXT_FOR_PROFILE_CUSTOMIZATION_BACKGROUND_COLOR = _("Background");
	public const string TEXT_FOR_PREFERENCES_BOOKS_DISCOVERY = _("Add folders to scan for books");
	public const string TEXT_FOR_PROFILE_BUTTON_LABEL = _("Profile");
	public const string TEXT_FOR_PREFERENCES_VALUES_RESET = _("Reset to default values");

	public const int SPACING_WIDGETS = 12;
	public const int SPACING_BUTTONS = 6;
	public const double ZOOM_CHANGE_VALUE = 0.1;
	public const int MARGIN_CHANGE_VALUE = 1;
	public const int LINE_HEIGHT_CHANGE_VALUE = 10;
	public const int MAX_BOOK_COVER_PER_ROW = 6;
	public const int MAX_NUMBER_OF_LINES_PER_PAGE = 30;
	public const int MAX_NUMBER_OF_CHARS_PER_LINE = 80;
	public const int MAX_NUMBER_OF_CHARS_FOR_ANNOTATION_TAB = 50;

	public const string TEXT_FOR_UNKNOWN_TITLE = _("Unknown Book");
	public const string TEXT_FOR_PREF_MENU_ABOUT_ITEM = _("About");
	public const string TEXT_FOR_PREF_MENU_PREFERENCES_ITEM = _("Preferences");

	public const string INSTALL_PREFIX = "/usr";
	public const string SEARCH_SCRIPT_LOCATION = INSTALL_PREFIX+"/share/bookworm/scripts/tasks/com.github.babluboy.bookworm.search.sh";
	public const string HTML_SCRIPT_LOCATION = INSTALL_PREFIX+"/share/bookworm/scripts/tasks/com.github.babluboy.bookworm.htmlscripts.txt";
	public const string MOBIUNPACK_SCRIPT_LOCATION = INSTALL_PREFIX+"/share/bookworm/scripts/mobi_lib/mobi_unpack.py";
	public const string CSS_LOCATION = INSTALL_PREFIX+"/share/bookworm/com.github.babluboy.bookworm.app.css";
	public const string PREV_PAGE_ICON_IMAGE_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm-go-previous.svg";
	public const string NEXT_PAGE_ICON_IMAGE_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm-go-next.svg";
	public const string SELECT_BOOK_ICON_IMAGE_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm-object-select-symbolic.svg";
	public const string ADD_BOOK_ICON_IMAGE_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm-list-add.svg";
	public const string REMOVE_BOOK_ICON_IMAGE_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm-list-remove.svg";
	public const string LIBRARY_VIEW_GRID_IMAGE_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm-view-grid-symbolic.svg";
	public const string LIBRARY_VIEW_LIST_IMAGE_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm-view-list-symbolic.svg";
	public const string MORE_LINE_HEIGHT_IMAGE_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm-line-height-more.png";
	public const string LESS_LINE_HEIGHT_IMAGE_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm-line-height-less.png";
	public const string MORE_LINE_WIDTH_IMAGE_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm-width-more.png";
	public const string LESS_LINE_WIDTH_IMAGE_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm-width-less.png";
	public const string RATING_NONE_IMAGE_ICON_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm-help-about-symbolic.svg";
	public const string RATING_SELECTED_IMAGE_ICON_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm-help-about.svg";
	public const string TEXT_LARGER_IMAGE_ICON_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm-format-text-larger-symbolic.svg";
	public const string TEXT_SMALLER_IMAGE_ICON_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm-format-text-smaller-symbolic.svg";
	public const string TEXT_ALIGN_LEFT_ICON_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm-format-justify-left.svg";
	public const string TEXT_ALIGN_RIGHT_ICON_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm-format-justify-right.svg";
	public const string RATING_1_IMAGE_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm_rating_1.png";
	public const string RATING_2_IMAGE_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm_rating_2.png";
	public const string RATING_3_IMAGE_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm_rating_3.png";
	public const string RATING_4_IMAGE_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm_rating_4.png";
	public const string RATING_5_IMAGE_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm_rating_5.png";
	public const string UPDATE_IMAGE_ICON_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm-insert-image.svg";
	public const string SELECTION_OPTION_IMAGE_SMALL_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm-selection-option.svg";
	public const string SELECTION_CHECKED_IMAGE_SMALL_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm-selection-checked.svg";
	public const string BOOK_INFO_IMAGE_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/16x16/actions/bookworm-help-info-symbolic.svg";
	public const string BOOKMARK_INACTIVE_IMAGE_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/24x24/actions/bookworm-bookmark-inactive.png";
	public const string BOOKMARK_ACTIVE_IMAGE_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/24x24/actions/bookworm-bookmark-active.png";
	public const string SELECTION_OPTION_IMAGE_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/24x24/actions/bookworm-selection-option.svg";
	public const string SELECTION_CHECKED_IMAGE_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/24x24/actions/bookworm-selection-checked.svg";
	public const string HEADERBAR_PROPERTIES_IMAGE_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/24x24/actions/bookworm-open-menu.svg";
	public const string DEFAULT_COVER_IMAGE_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/default_covers/apps/bookworm-default-cover-N.svg";
	public const string PLACEHOLDER_COVER_IMAGE_LOCATION = INSTALL_PREFIX+"/share/bookworm/icons/hicolor/default_covers/apps/bookworm-placeholder-cover.svg";
	public const string EBOOK_EXTRACTION_LOCATION = "/tmp/bookworm/";
	public const string PREFIX_FOR_FILE_URL = "file:///";

	public const string FILE_CHOOSER_FILTER_EBOOKS[] = {"*.epub", "*.pdf", "*.cbr", "*.cbz", "*.mobi", "*.prc"};
	public const string FILE_CHOOSER_FILTER_IMAGES[] = {"*.jpg", "*.jpeg", "*.gif", "*.png", "*.svg"};


	public const string BOOKWORM_READING_MODE[] = {"PROFILE1","PROFILE2","PROFILE3"};
	public const string BOOKWORM_UI_STATES[] = {"LIBRARY_MODE_GRID",
																										 "READING_MODE",
																										 "GRID_SELECTION_MODE",
																										 "GRID_SELECTED_MODE",
																										 "CONTENT_MODE",
																										 "LIBRARY_MODE_LIST",
																										 "LIST_SELECTION_MODE",
																										 "LIST_SELECTED_MODE"
																										};
	public const string IDENTIFIER_FOR_PROPERTY_VALUE = "==";
	public const string IDENTIFIER_FOR_PROPERTY_START = "~~";
	public const string IDENTIFIER_FOR_PROPERTY_END = "##\n";
	public const string EPUB_MIME_SPECIFICATION_FILENAME = "mimetype";
	public const string EPUB_MIME_SPECIFICATION_CONTENT = "application/epub+zip";
	public const string EPUB_META_INF_FILENAME = "META-INF/container.xml";
	public const string[] TAG_NAME_WITH_PATHS = {"src=\"", "xlink:href=\"", "<link href=\""};
	public const string DYNAMIC_CSS_CONTENT = " GtkButton.PROFILE_BUTTON_1 { color: <profile_1_color>; background-color: <profile_1_bgcolor>; border-color: #B0C4DE; } GtkButton.PROFILE_BUTTON_2 { color: <profile_2_color>; background-color: <profile_2_bgcolor>; border-color: #B0C4DE; } GtkButton.PROFILE_BUTTON_3 { color: <profile_3_color>; background-color: <profile_3_bgcolor>; border-color: #B0C4DE; }";
	public const string COMICS_HTML_TEMPLATE = "<html><style>img{max-width: 100%;height: auto;}</style><body><img src=\"<image-location>\"></body></html>";
}
