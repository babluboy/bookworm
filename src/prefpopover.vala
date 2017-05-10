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

  public static Gtk.Popover createPrefPopOver(Gtk.Button popWidget){
    if(prefPopover != null){
      return prefPopover;
    }
    prefPopover = new Gtk.Popover (popWidget);

    Gtk.Image menu_icon_text_large = new Gtk.Image.from_icon_name ("format-text-larger-symbolic", IconSize.LARGE_TOOLBAR);
    Gtk.Button textLargerButton = new Gtk.Button();
    textLargerButton.set_image (menu_icon_text_large);
    textLargerButton.set_halign(Gtk.Align.START);
    textLargerButton.set_relief (ReliefStyle.NONE);

    Gtk.Image menu_icon_text_small = new Gtk.Image.from_icon_name ("format-text-smaller-symbolic", IconSize.LARGE_TOOLBAR);
    Gtk.Button textSmallerButton = new Gtk.Button();
    textSmallerButton.set_image (menu_icon_text_small);
    textSmallerButton.set_halign(Gtk.Align.END);
    textSmallerButton.set_relief (ReliefStyle.NONE);

    Gtk.Box textSizeBox = new Gtk.Box(Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_BUTTONS);
    textSizeBox.pack_start(textSmallerButton, false, false);
    textSizeBox.pack_end(textLargerButton, false, false);

    Gtk.Image day_profile_image = new Gtk.Image ();
    day_profile_image.set_from_file (Constants.DAY_PROFILE_IMAGE_LOCATION);
    Gtk.Button dayProfileButton = new Gtk.Button();
    dayProfileButton.set_image (day_profile_image);
    dayProfileButton.set_halign(Gtk.Align.START);
    dayProfileButton.set_relief (ReliefStyle.NONE);

    Gtk.Image night_profile_image = new Gtk.Image ();
    night_profile_image.set_from_file (Constants.NIGHT_PROFILE_IMAGE_LOCATION);
    Gtk.Button nightProfileButton = new Gtk.Button();
    nightProfileButton.set_image (night_profile_image);
    nightProfileButton.set_halign(Gtk.Align.END);
    nightProfileButton.set_relief (ReliefStyle.NONE);

    Gtk.Box profileBox = new Gtk.Box(Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_BUTTONS);
    profileBox.pack_start(dayProfileButton, false, false);
    profileBox.pack_end(nightProfileButton, false, false);

    Gtk.Image icon_margin_indent_more = new Gtk.Image.from_icon_name ("format-indent-more-symbolic", IconSize.MENU);
    Gtk.Button marginIncreaseButton = new Gtk.Button();
    marginIncreaseButton.set_image (icon_margin_indent_more);
    marginIncreaseButton.set_halign(Gtk.Align.START);
    marginIncreaseButton.set_relief (ReliefStyle.NONE);

    Gtk.Image icon_margin_indent_less = new Gtk.Image.from_icon_name ("format-indent-less-symbolic", IconSize.MENU);
    Gtk.Button marginDecreaseButton = new Gtk.Button();
    marginDecreaseButton.set_image (icon_margin_indent_less);
    marginDecreaseButton.set_halign(Gtk.Align.END);
    marginDecreaseButton.set_relief (ReliefStyle.NONE);

    Gtk.Box marginBox = new Gtk.Box(Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_BUTTONS);
    marginBox.pack_start(marginIncreaseButton, false, false);
    marginBox.pack_end(marginDecreaseButton, false, false);

    Gtk.Box prefBox = new Gtk.Box(Orientation.VERTICAL, BookwormApp.Constants.SPACING_BUTTONS);
    prefBox.set_border_width(BookwormApp.Constants.SPACING_WIDGETS);
    prefBox.pack_start(textSizeBox, false, false);
    prefBox.pack_start(new Gtk.HSeparator() , true, true, 0);
    prefBox.pack_start(marginBox, false, false);
    prefBox.pack_start(new Gtk.HSeparator() , true, true, 0);
    prefBox.pack_start(profileBox, false, false);

    prefPopover.add(prefBox);

    //Add actions to Popover menu
    textLargerButton.clicked.connect (() => {
      BookwormApp.AppWindow.aWebView.set_zoom_level (BookwormApp.AppWindow.aWebView.get_zoom_level() + BookwormApp.Constants.ZOOM_CHANGE_VALUE);
    });

    textSmallerButton.clicked.connect (() => {
      BookwormApp.AppWindow.aWebView.set_zoom_level (BookwormApp.AppWindow.aWebView.get_zoom_level() - BookwormApp.Constants.ZOOM_CHANGE_VALUE);
    });

    dayProfileButton.clicked.connect (() => {
      BookwormApp.Bookworm.applyProfile(BookwormApp.Constants.BOOKWORM_READING_MODE[0]);
      //call the rendered page if UI State is in reading mode
      if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[1]){
        BookwormApp.Book currentBookForViewChange = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
        currentBookForViewChange = BookwormApp.Bookworm.renderPage(BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead), "");
        BookwormApp.Bookworm.libraryViewMap.set(BookwormApp.Bookworm.locationOfEBookCurrentlyRead, currentBookForViewChange);
      }
    });

    nightProfileButton.clicked.connect (() => {
      BookwormApp.Bookworm.applyProfile(BookwormApp.Constants.BOOKWORM_READING_MODE[1]);
      //call the rendered page if UI State is in reading mode
      if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[1]){
        BookwormApp.Book currentBookForViewChange = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
        currentBookForViewChange = BookwormApp.Bookworm.renderPage(BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead), "");
        BookwormApp.Bookworm.libraryViewMap.set(BookwormApp.Bookworm.locationOfEBookCurrentlyRead, currentBookForViewChange);
      }
    });

    marginIncreaseButton.clicked.connect (() => {
      if(BookwormApp.Bookworm.settings.reading_width.to_int() < 40){
        BookwormApp.Bookworm.settings.reading_width = (BookwormApp.Bookworm.settings.reading_width.to_int() + BookwormApp.Constants.MARGIN_CHANGE_VALUE).to_string();
        if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[1]){
          BookwormApp.Book currentBookForMarginIncrease = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
          currentBookForMarginIncrease = BookwormApp.Bookworm.renderPage(BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead), "");
          BookwormApp.Bookworm.libraryViewMap.set(BookwormApp.Bookworm.locationOfEBookCurrentlyRead, currentBookForMarginIncrease);
        }
      }
    });

    marginDecreaseButton.clicked.connect (() => {
      if(BookwormApp.Bookworm.settings.reading_width.to_int() > 1){
        BookwormApp.Bookworm.settings.reading_width = (BookwormApp.Bookworm.settings.reading_width.to_int() - BookwormApp.Constants.MARGIN_CHANGE_VALUE).to_string();
        if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[1]){
          BookwormApp.Book currentBookForMarginDecrease = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
          currentBookForMarginDecrease = BookwormApp.Bookworm.renderPage(BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead), "");
          BookwormApp.Bookworm.libraryViewMap.set(BookwormApp.Bookworm.locationOfEBookCurrentlyRead, currentBookForMarginDecrease);
        }
      }
    });

    return prefPopover;
  }
}
