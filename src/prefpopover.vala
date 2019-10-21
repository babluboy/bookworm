/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and provides the pop over
* menu for user preferences for font, profile, zoom, etc
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
public class BookwormApp.PreferencesMenu {
    public static Gtk.Popover prefPopover;

    public static Gtk.Popover createPrefPopOver (Gtk.Button popWidget) {
        debug ("[START] [FUNCTION:createPrefPopOver]");
        if (prefPopover != null) {
            return prefPopover;
        }
        prefPopover = new Gtk.Popover (popWidget);

        StringBuilder profileNameText = new StringBuilder ();

        Gtk.Button textLargerButton = new Gtk.Button ();
        textLargerButton.set_image (BookwormApp.Bookworm.pref_menu_icon_text_large);
        textLargerButton.set_halign (Gtk.Align.START);
        textLargerButton.set_relief (ReliefStyle.NONE);
        textLargerButton.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_FONT_SIZE_INCREASE);

        Gtk.Button textSmallerButton = new Gtk.Button ();
        textSmallerButton.set_image (BookwormApp.Bookworm.pref_menu_icon_text_small);
        textSmallerButton.set_halign (Gtk.Align.END);
        textSmallerButton.set_relief (ReliefStyle.NONE);
        textSmallerButton.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_FONT_SIZE_DECREASE);

        Gtk.Box textSizeBox = new Gtk.Box (Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_BUTTONS);
        textSizeBox.pack_start (textSmallerButton, false, false);
        textSizeBox.pack_end (textLargerButton, false, false);
        textSizeBox.set_halign (Gtk.Align.CENTER);

        Gtk.Button alignLeftButton = new Gtk.Button ();
        alignLeftButton.set_image (BookwormApp.Bookworm.pref_menu_icon_align_left);
        alignLeftButton.set_halign (Gtk.Align.START);
        alignLeftButton.set_relief (ReliefStyle.NONE);
        alignLeftButton.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_READING_LEFT_ALIGN);

        Gtk.Button alignRightButton = new Gtk.Button ();
        alignRightButton.set_image (BookwormApp.Bookworm.pref_menu_icon_align_right);
        alignRightButton.set_halign (Gtk.Align.END);
        alignRightButton.set_relief (ReliefStyle.NONE);
        alignRightButton.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_READING_RIGHT_ALIGN);

        Gtk.Box textAlignBox = new Gtk.Box (Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_BUTTONS);
        textAlignBox.pack_start (alignLeftButton, false, false);
        textAlignBox.pack_end (alignRightButton, false, false);
        textAlignBox.set_halign (Gtk.Align.CENTER);

        Gtk.Button profileButton1 = new Gtk.Button ();
        profileButton1.get_style_context ().add_class ("PROFILE_BUTTON_1");
        profileNameText.assign (BookwormApp.Constants.TEXT_FOR_PROFILE_BUTTON_LABEL);
        profileButton1.set_label (profileNameText.append (" 1").str);
        profileButton1.set_halign (Gtk.Align.START);
        profileButton1.set_relief (ReliefStyle.NONE);
        profileButton1.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_PROFILE);

        Gtk.Button profileButton2 = new Gtk.Button ();
        profileButton2.get_style_context ().add_class ("PROFILE_BUTTON_2");
        profileNameText.assign (BookwormApp.Constants.TEXT_FOR_PROFILE_BUTTON_LABEL);
        profileButton2.set_label (profileNameText.append (" 2").str);
        profileButton2.set_halign (Gtk.Align.START);
        profileButton2.set_relief (ReliefStyle.NONE);
        profileButton2.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_PROFILE);

        Gtk.Button profileButton3 = new Gtk.Button ();
        profileButton3.get_style_context ().add_class ("PROFILE_BUTTON_3");
        profileNameText.assign (BookwormApp.Constants.TEXT_FOR_PROFILE_BUTTON_LABEL);
        profileButton3.set_label (profileNameText.append (" 3").str);
        profileButton3.set_halign (Gtk.Align.END);
        profileButton3.set_relief (ReliefStyle.NONE);
        profileButton3.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_PROFILE);

        Gtk.Box profileBox = new Gtk.Box (Orientation.VERTICAL, BookwormApp.Constants.SPACING_BUTTONS);
        profileBox.pack_start (profileButton1, false, false);
        profileBox.pack_start (profileButton2, false, false);
        profileBox.pack_end (profileButton3, false, false);
        profileBox.set_halign (Gtk.Align.CENTER);

        Gtk.Image icon_width_indent_less = new Gtk.Image ();
        icon_width_indent_less.set_from_resource (Constants.LESS_LINE_WIDTH_IMAGE_LOCATION);
        Gtk.Button marginDecreaseButton = new Gtk.Button ();
        marginDecreaseButton.set_image (icon_width_indent_less);
        marginDecreaseButton.set_halign (Gtk.Align.START);
        marginDecreaseButton.set_relief (ReliefStyle.NONE);
        marginDecreaseButton.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_LINE_WIDTH_DECREASE);

        Gtk.Image icon_width_indent_more = new Gtk.Image ();
        icon_width_indent_more.set_from_resource (Constants.MORE_LINE_WIDTH_IMAGE_LOCATION);
        Gtk.Button marginIncreaseButton = new Gtk.Button ();
        marginIncreaseButton.set_image (icon_width_indent_more);
        marginIncreaseButton.set_halign (Gtk.Align.END);
        marginIncreaseButton.set_relief (ReliefStyle.NONE);
        marginIncreaseButton.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_LINE_WIDTH_INCREASE);

        Gtk.Box marginBox = new Gtk.Box (Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_BUTTONS);
        marginBox.pack_start (marginIncreaseButton, false, false);
        marginBox.pack_end (marginDecreaseButton, false, false);
        marginBox.set_halign (Gtk.Align.CENTER);

        Gtk.Image icon_line_height_less = new Gtk.Image ();
        icon_line_height_less.set_from_resource (Constants.LESS_LINE_HEIGHT_IMAGE_LOCATION);
        Gtk.Button heightDecreaseButton = new Gtk.Button ();
        heightDecreaseButton.set_image (icon_line_height_less);
        heightDecreaseButton.set_halign (Gtk.Align.START);
        heightDecreaseButton.set_relief (ReliefStyle.NONE);
        heightDecreaseButton.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_LINE_HEIGHT_DECREASE);

        Gtk.Image icon_line_height_more = new Gtk.Image ();
        icon_line_height_more.set_from_resource (Constants.MORE_LINE_HEIGHT_IMAGE_LOCATION);
        Gtk.Button heightIncreaseButton = new Gtk.Button ();
        heightIncreaseButton.set_image (icon_line_height_more);
        heightIncreaseButton.set_halign (Gtk.Align.START);
        heightIncreaseButton.set_relief (ReliefStyle.NONE);
        heightIncreaseButton.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_LINE_HEIGHT_INCREASE);

        Gtk.Box lineHeightBox = new Gtk.Box (Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_BUTTONS);
        lineHeightBox.pack_start (heightIncreaseButton, false, false);
        lineHeightBox.pack_end (heightDecreaseButton, false, false);
        lineHeightBox.set_halign (Gtk.Align.CENTER);

        Gtk.Box prefBox = new Gtk.Box (Orientation.VERTICAL, BookwormApp.Constants.SPACING_BUTTONS);
        prefBox.set_border_width (BookwormApp.Constants.SPACING_WIDGETS);
        prefBox.pack_start (textSizeBox, false, false);
        prefBox.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) , true, true, 0);
        prefBox.pack_start (textAlignBox, false, false);
        prefBox.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) , true, true, 0);
        prefBox.pack_start (marginBox, false, false);
        prefBox.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) , true, true, 0);
        prefBox.pack_start (lineHeightBox, false, false);
        prefBox.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) , true, true, 0);
        prefBox.pack_start (profileBox, false, false);

        prefPopover.add (prefBox);

        //Add actions to Popover menu
        textLargerButton.clicked.connect (() => {
            BookwormApp.AppWindow.aWebView.set_zoom_level (
                BookwormApp.AppWindow.aWebView.get_zoom_level () +
                BookwormApp.Constants.ZOOM_CHANGE_VALUE);
        });

        textSmallerButton.clicked.connect (() => {
            BookwormApp.AppWindow.aWebView.set_zoom_level (
                BookwormApp.AppWindow.aWebView.get_zoom_level () -
                BookwormApp.Constants.ZOOM_CHANGE_VALUE);
        });

        profileButton1.clicked.connect (() => {
            BookwormApp.Bookworm.settings.reading_profile = BookwormApp.Constants.BOOKWORM_READING_MODE[0];
            //Refresh the page if it is open
            BookwormApp.contentHandler.refreshCurrentPage ();
        });

        profileButton2.clicked.connect (() => {
            BookwormApp.Bookworm.settings.reading_profile = BookwormApp.Constants.BOOKWORM_READING_MODE[1];
            //Refresh the page if it is open
            BookwormApp.contentHandler.refreshCurrentPage ();
        });

        profileButton3.clicked.connect (() => {
            BookwormApp.Bookworm.settings.reading_profile = BookwormApp.Constants.BOOKWORM_READING_MODE[2];
            //Refresh the page if it is open
            BookwormApp.contentHandler.refreshCurrentPage ();
        });

        marginDecreaseButton.clicked.connect (() => {
            if (int.parse (BookwormApp.Bookworm.settings.reading_width) <= 40) {
                BookwormApp.Bookworm.settings.reading_width = (
                    int.parse (BookwormApp.Bookworm.settings.reading_width) +
                    BookwormApp.Constants.MARGIN_CHANGE_VALUE).to_string ();
                //Refresh the page if it is open
                BookwormApp.contentHandler.refreshCurrentPage ();
            }
        });

        marginIncreaseButton.clicked.connect (() => {
            if (int.parse (BookwormApp.Bookworm.settings.reading_width) >= 1) {
                BookwormApp.Bookworm.settings.reading_width = (
                    int.parse (BookwormApp.Bookworm.settings.reading_width) -
                    BookwormApp.Constants.MARGIN_CHANGE_VALUE).to_string ();
                //Refresh the page if it is open
                BookwormApp.contentHandler.refreshCurrentPage ();
            }
        });

        heightDecreaseButton.clicked.connect (() => {
            if (int.parse (BookwormApp.Bookworm.settings.reading_line_height) >= 100) {
                BookwormApp.Bookworm.settings.reading_line_height = (
                    int.parse (BookwormApp.Bookworm.settings.reading_line_height) -
                    BookwormApp.Constants.LINE_HEIGHT_CHANGE_VALUE).to_string ();
                //Refresh the page if it is open
                BookwormApp.contentHandler.refreshCurrentPage ();
            }
        });

        heightIncreaseButton.clicked.connect (() => {
            if (int.parse (BookwormApp.Bookworm.settings.reading_line_height) <= 500) {
                BookwormApp.Bookworm.settings.reading_line_height = (
                    int.parse (BookwormApp.Bookworm.settings.reading_line_height) +
                    BookwormApp.Constants.LINE_HEIGHT_CHANGE_VALUE).to_string ();
                //Refresh the page if it is open
                BookwormApp.contentHandler.refreshCurrentPage ();
            }
        });

        alignLeftButton.clicked.connect (() => {
            BookwormApp.Bookworm.settings.text_alignment = "left";
            //Refresh the page if it is open
            BookwormApp.contentHandler.refreshCurrentPage ();
        });

        alignRightButton.clicked.connect (() => {
            BookwormApp.Bookworm.settings.text_alignment = "right";
            //Refresh the page if it is open
            BookwormApp.contentHandler.refreshCurrentPage ();
        });

        prefPopover.closed.connect (() => {
            //set the focus to the webview to capture keypress events
            BookwormApp.AppWindow.aWebView.grab_focus ();
        });

        debug ("[END] [FUNCTION:createPrefPopOver]");
        return prefPopover;
    }
}
