/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and creates the dialog
* menus like the Preference Dialog
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

public class BookwormApp.AppDialog : Gtk.Dialog {

	public AppDialog () {

	}

	public static void createPreferencesDialog () {
		AppDialog dialog = new AppDialog ();
    dialog.title = BookwormApp.Constants.TEXT_FOR_PREFERENCES_DIALOG_TITLE;
		dialog.border_width = 5;
		dialog.set_default_size (600, 200);
		dialog.destroy.connect (Gtk.main_quit);

    Gtk.Box prefBox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_WIDGETS);
    Gtk.Label colourScheme = new Gtk.Label (BookwormApp.Constants.TEXT_FOR_PREFERENCES_COLOUR_SCHEME);
    prefBox.pack_start(colourScheme, false, false);

    Gtk.Switch nightModeSwitch = new Gtk.Switch ();
    prefBox.pack_end(nightModeSwitch, false, false);
    //Set the switch to on if the state is in Night Mode
    if(BookwormApp.Constants.BOOKWORM_READING_MODE[1] == BookwormApp.Bookworm.settings.reading_profile)
      nightModeSwitch.set_active (true);

    Gtk.Box content = dialog.get_content_area () as Gtk.Box;
		content.pack_start (prefBox, false, false, 0);
		content.spacing = BookwormApp.Constants.SPACING_WIDGETS;

    dialog.show_all ();

    //Set up Actions
    nightModeSwitch.notify["active"].connect (() => {
			if (nightModeSwitch.active) {
        BookwormApp.Bookworm.applyProfile(BookwormApp.Constants.BOOKWORM_READING_MODE[1]);
        //call the rendered page if UI State is in reading mode
        if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[1]){
          BookwormApp.Book currentBookForViewChange = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
          currentBookForViewChange = BookwormApp.Bookworm.renderPage(BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead), "");
          BookwormApp.Bookworm.libraryViewMap.set(BookwormApp.Bookworm.locationOfEBookCurrentlyRead, currentBookForViewChange);
        }
			}else{
        BookwormApp.Bookworm.applyProfile(BookwormApp.Constants.BOOKWORM_READING_MODE[0]);
        //call the rendered page if UI State is in reading mode
        if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[1]){
          BookwormApp.Book currentBookForViewChange = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
          currentBookForViewChange = BookwormApp.Bookworm.renderPage(BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead), "");
          BookwormApp.Bookworm.libraryViewMap.set(BookwormApp.Bookworm.locationOfEBookCurrentlyRead, currentBookForViewChange);
        }
			}
		});
	}
}
