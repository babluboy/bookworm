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
	public const string bookworm_version = "0.6";
	public const string program_name = "Bookworm";
	public const string app_years = "2017";
	public const string app_icon = "bookworm";
	public const string[] about_authors = {"Siddhartha Das <bablu.boy@gmail.com>"};
	public const string about_comments = _("An eBook Reader");
	public const Gtk.License about_license_type = Gtk.License.GPL_3_0;
	public const string translator_credits = _("Launchpad Translators");
	public const string main_url = "https://github.com/babluboy/bookworm/wiki";
	public const string bug_url = "https://github.com/babluboy/bookworm/issues";
	public const string help_url = "https://github.com/babluboy/bookworm/wiki";
	public const string translate_url = "https://translations.launchpad.net/bookworm";

	public const string TEXT_FOR_ABOUT_DIALOG_WEBSITE = _("Website");
	public const string TEXT_FOR_ABOUT_DIALOG_WEBSITE_URL = "https://github.com/babluboy/bookworm/wiki";
	public const string TEXT_FOR_NOT_AVAILABLE = _("Not Available");
	public const string TEXT_FOR_SUBTITLE_HEADERBAR = _("eBook Reader");
	public const string TEXT_FOR_HEADERBAR_BOOK_SEARCH = _("Search this book...");
	public const string TEXT_FOR_HEADERBAR_LIBRARY_SEARCH = _("Search for Title, Author and Tags");
	public const string TEXT_FOR_WELCOME_MESSAGE_TITLE = _("Looks like Bookworm has no books !");
	public const string TEXT_FOR_WELCOME_MESSAGE_SUBTITLE = _("Build your library by adding eBooks");
	public const string TEXT_FOR_WELCOME_OPENDIR_MESSAGE = _("Select an eBook to read");
	public const string TEXT_FOR_EXTRACTION_ISSUE = _("Problem in extracting contents of book. Check if book is available at location : ");
	public const string TEXT_FOR_MIMETYPE_ISSUE = _("Invalid Mime type dectected. Check book format at location : ");
	public const string TEXT_FOR_CONTENT_ISSUE = _("Invalid content found. Ensure valid eBook file at location : ");
	public const string TEXT_FOR_FORMAT_NOT_SUPPORTED = _("Bookworm does not support the format of the file found at location : ");
	public const string TEXT_FOR_LIBRARY_BUTTON = _("Library");
	public const string TEXT_FOR_RESUME_BUTTON = _("Resume");
	public const string TEXT_FOR_INFO_TAB_CONTENTS = _("Contents");
	public const string TEXT_FOR_INFO_TAB_CONTENT_PREFIX = _("Content #");
	public const string TEXT_FOR_INFO_TAB_BOOKMARKS = _("Bookmarks");
	public const string TEXT_FOR_BOOKMARKS = _("Bookmark #NNN for Section PPP");
	public const string TEXT_FOR_BOOKMARKS_FOUND = _("Click on a link to jump to bookmarked section");
	public const string TEXT_FOR_BOOKMARKS_NOT_FOUND = _("No bookmarks set in BBB, click the bookworm icon on the header bar to boomark the page");
	public const string TEXT_FOR_INFO_TAB_SEARCHRESULTS = _("Search Results");
	public const string TEXT_FOR_SEARCH_RESULTS_FOUND = _("Found the following matches for '$$$' in &&&:");
	public const string TEXT_FOR_SEARCH_RESULTS_NOT_FOUND = _("No matches found for '$$$' in &&&");
	public const string TEXT_FOR_BOOK_CONTEXTMENU_HEADER = _("Edit Info for");
	public const string TEXT_FOR_BOOK_CONTEXTMENU_UPDATE_COVER_IMAGE = _("Update Cover Image");
	public const string TEXT_FOR_BOOK_CONTEXTMENU_UPDATE_TITLE = _("Update Title");
	public const string TEXT_FOR_BOOK_CONTEXTMENU_UPDATE_TAGS = _("Update Tags");
	public const string TEXT_FOR_BOOK_CONTEXTMENU_UPDATE_COVER = _("Update Cover Image");

	public const string TEXT_FOR_PREFERENCES_DIALOG_TITLE = _("Preferences");
	public const string TEXT_FOR_PREFERENCES_COLOUR_SCHEME = _("Turn on Night Mode");

	public const int SPACING_WIDGETS = 12;
	public const int SPACING_BUTTONS = 6;
	public const double ZOOM_CHANGE_VALUE = 0.1;
	public const string RGBA_HEX_WHITE = "#ffffff";
	public const string RGBA_HEX_BLACK = "#002B36";

	public const string TEXT_FOR_UNKNOWN_TITLE = _("Unknown Book");
	public const string TEXT_FOR_PREF_MENU_ABOUT_ITEM = _("About");
	public const string TEXT_FOR_PREF_MENU_PREFERENCES_ITEM = _("Preferences");

	public static const string CSS_LOCATION = "/usr/share/bookworm/com.github.babluboy.bookworm.app.css";
	public static const string PREV_PAGE_ICON_IMAGE_LOCATION = "/usr/share/bookworm/icons/hicolor/16x16/actions/bookworm-go-previous.svg";
	public static const string NEXT_PAGE_ICON_IMAGE_LOCATION = "/usr/share/bookworm/icons/hicolor/16x16/actions/bookworm-go-next.svg";
	public static const string ADD_BOOK_ICON_IMAGE_LOCATION = "/usr/share/bookworm/icons/hicolor/16x16/actions/bookworm-list-add.svg";
	public static const string REMOVE_BOOK_ICON_IMAGE_LOCATION = "/usr/share/bookworm/icons/hicolor/16x16/actions/bookworm-list-remove.svg";
	public static const string LIBRARY_VIEW_IMAGE_LOCATION = "/usr/share/bookworm/icons/hicolor/16x16/actions/bookworm-view-grid-symbolic.svg";
	public static const string CONTENTS_VIEW_IMAGE_LOCATION = "/usr/share/bookworm/icons/hicolor/24x24/actions/bookworm-view-list-symbolic.png";
	public static const string BOOKMARK_INACTIVE_IMAGE_LOCATION = "/usr/share/bookworm/icons/hicolor/24x24/actions/bookworm-bookmark-inactive.png";
	public static const string BOOKMARK_ACTIVE_IMAGE_LOCATION = "/usr/share/bookworm/icons/hicolor/24x24/actions/bookworm-bookmark-active.png";
	public static const string NIGHT_PROFILE_IMAGE_LOCATION = "/usr/share/bookworm/icons/hicolor/24x24/actions/bookworm-profile-night.png";
	public static const string DAY_PROFILE_IMAGE_LOCATION = "/usr/share/bookworm/icons/hicolor/24x24/actions/bookworm-profile-day.png";
	public static const string SELECTION_IMAGE_BUTTON_LOCATION = "/usr/share/bookworm/icons/hicolor/24x24/actions/bookworm-selection.svg";
	public static const string SELECTION_OPTION_IMAGE_LOCATION = "/usr/share/bookworm/icons/hicolor/24x24/actions/bookworm-selection-option.svg";
	public static const string SELECTION_CHECKED_IMAGE_LOCATION = "/usr/share/bookworm/icons/hicolor/24x24/actions/bookworm-selection-checked.svg";
	public static const string HEADERBAR_PROPERTIES_IMAGE_LOCATION = "/usr/share/bookworm/icons/hicolor/24x24/actions/bookworm-open-menu.svg";
	public static const string DEFAULT_COVER_IMAGE_LOCATION = "/usr/share/bookworm/icons/hicolor/256x256/apps/bookworm-default-cover-N.png";
	public static const string PLACEHOLDER_COVER_IMAGE_LOCATION = "/usr/share/bookworm/icons/hicolor/256x256/apps/bookworm-placeholder-cover.png";
	public static const string EBOOK_EXTRACTION_LOCATION = "/tmp/bookworm/";
	public static const string PREFIX_FOR_FILE_URL = "file:///";

	public static const int MAX_BOOK_COVER_PER_ROW = 6;
	public static const int MAX_NUMBER_OF_LINES_PER_PAGE = 30;
	public static const int MAX_NUMBER_OF_CHARS_PER_LINE = 80;
	public static const string FILE_CHOOSER_FILTER_ALL_FILES = _("All Files");

	public static const string BOOKWORM_READING_MODE[] = {"DAY MODE",
																										 		"NIGHT MODE",
																										   };
	public static const string BOOKWORM_UI_STATES[] = {"LIBRARY_MODE",
																										 "READING_MODE",
																										 "SELECTION_MODE",
																										 "SELECTED_MODE",
																										 "CONTENT_MODE",
																										};
	public static const string IDENTIFIER_FOR_PROPERTY_VALUE = "==";
	public static const string IDENTIFIER_FOR_PROPERTY_START = "~~";
	public static const string IDENTIFIER_FOR_PROPERTY_END = "##\n";
	public const string EPUB_MIME_SPECIFICATION_FILENAME = "mimetype";
	public const string EPUB_MIME_SPECIFICATION_CONTENT = "application/epub+zip";
	public const string EPUB_META_INF_FILENAME = "META-INF/container.xml";
	public const string[] TAG_NAME_WITH_PATHS = {"src=\"", "xlink:href=\"", "<link href=\""};
	public const string JAVASCRIPT_FOR_WHITE_COLOR_FONT = "onload=\"javascript:document.getElementsByTagName('BODY')[0].style.color='white';\"";
}
