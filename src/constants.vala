/* Copyright 2016 Siddhartha Das (bablu.boy@gmail.com)
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

namespace BookwormApp.Constants {
	public const string bookworm_version = "0.1";
	public const string TEXT_FOR_NOT_AVAILABLE = _("Not Available");
	public const string TEXT_FOR_SUBTITLE_HEADERBAR = _("eBook Reader");
	public const string TEXT_FOR_SEARCH_HEADERBAR = _("Filter results...");

	public const int SPACING_WIDGETS = 12;
	public const int SPACING_BUTTONS = 6;

	public const string TEXT_FOR_HEADERBAR_MENU_PREFS = _("Something");
	public const string TEXT_FOR_HEADERBAR_MENU_EXPORT = _("Something Else");

	public static const string PREV_PAGE_ICON_IMAGE_LOCATION = "/usr/share/icons/hicolor/16x16/actions/bookworm-go-previous.svg";
	public static const string NEXT_PAGE_ICON_IMAGE_LOCATION = "/usr/share/icons/hicolor/16x16/actions/bookworm-go-next.svg";
	public static const string ADD_BOOK_ICON_IMAGE_LOCATION = "/usr/share/icons/hicolor/16x16/actions/bookworm-list-add.svg";
	public static const string REMOVE_BOOK_ICON_IMAGE_LOCATION = "/usr/share/icons/hicolor/16x16/actions/bookworm-list-remove.svg";
	public static const string LIBRARY_VIEW_IMAGE_LOCATION = "/usr/share/icons/hicolor/16x16/actions/bookworm-view-grid-symbolic.svg";
	public static const string CONTENTS_VIEW_IMAGE_LOCATION = "/usr/share/icons/hicolor/16x16/actions/bookworm-view-list-symbolic.svg";
	public static const string EPUB_EXTRACTION_LOCATION = "/tmp/bookworm/";

	public static const string BOOKWORM_UI_STATES[] = {"LIBRARY_MODE","READING_MODE"};
	public static const string IDENTIFIER_FOR_PROPERTY_VALUE = "==";
	public static const string IDENTIFIER_FOR_PROPERTY_START = "~~";
	public static const string IDENTIFIER_FOR_PROPERTY_END = "##\n";

	public const string EPUB_MIME_SPECIFICATION_FILENAME = "mimetype";
	public const string EPUB_MIME_SPECIFICATION_CONTENT = "application/epub+zip";
	public const string EPUB_META_INF_FILENAME = "META-INF/container.xml";
}
