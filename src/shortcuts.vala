/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and is used for defining
* the keyboard shortcuts for Bookworm
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
using Gee;

public class BookwormApp.Shortcuts {

    public static void removeOldShortcutsFromWidgets () {
        BookwormApp.Bookworm.shortcutAssocs.foreachAssoc ((assoc) => {
            foreach (var shortcutStruct in assoc.getOldShortcuts ()) {
                BookwormApp.Bookworm.accel.disconnect_key (shortcutStruct.keyval, shortcutStruct.get_modifier_type ());
            }
        });
    }

    public static void attachShortcutsToWidgets () {
        BookwormApp.Bookworm.shortcutAssocs.foreachAssoc ((assoc) => {
            assoc.foreachShortcut ((shortcutStruct) => {
                debug ("assoc action: " + assoc.action +
                        ", shortcutStruct: " + shortcutStruct.to_settings_string() +
                        ", uistring: " + shortcutStruct.to_ui_string() +
                        ", modifier: " + shortcutStruct.get_modifier_type().to_string()
                        );
                BookwormApp.Bookworm.accel.connect (shortcutStruct.keyval, shortcutStruct.get_modifier_type (), Gtk.AccelFlags.VISIBLE, () => {
                    debug ("about to dispatch assoc action: " + assoc.action +
                        ", shortcutStruct: " + shortcutStruct.to_settings_string() +
                        ", uistring: " + shortcutStruct.to_ui_string() +
                        ", modifier: " + shortcutStruct.get_modifier_type().to_string()
                        );
                    return BookwormApp.Shortcuts.dispatchByActionName (assoc.action, shortcutStruct);
                });
            });
        });

        BookwormApp.AppWindow.aWebView.key_press_event.connect((event) => {
            debug ("aWebView key_press_event handler.");
            var modifiers_state = (event.state & (Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.MOD1_MASK | Gdk.ModifierType.SHIFT_MASK));
            var shortcutStruct = new ShortcutStruct (event.keyval, modifiers_state);
            //BookwormApp.Bookworm.accel.activate (GLib.Quark.from_string("str"), BookwormApp.Bookworm.window, event.keyval, shortcutStruct.get_modifier_type ());
            /*
            bool activatedAccel = BookwormApp.Bookworm.accel.activate (
                GLib.Quark.from_string(""),
                BookwormApp.Bookworm.window,
                Gdk.Key.Cyrillic_ZE,
                Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK);
            debug ("activatedAccel" + activatedAccel.to_string() );
            */
            var assocHoldingShortcut = BookwormApp.Bookworm.shortcutAssocs.findAssoc ((assoc) =>
                                                                                      assoc.containsShortcut (shortcutStruct) &&
                                                                                      (assoc.shortcutGroup & ShortcutGroup.READING_VIEW_GROUP) != 0);
            debug ("shortcutStruct: " + shortcutStruct.to_settings_string() +
                  ", uistring: " + shortcutStruct.to_ui_string() +
                  ", assocsCount: " + BookwormApp.Bookworm.shortcutAssocs.assocsCount ().to_string ());
            if (assocHoldingShortcut == null) {
                debug ("assocHoldingShortcut is null");
            } else {
                debug ("assocHoldingShortcut action: " + assocHoldingShortcut.action);
                return BookwormApp.Shortcuts.dispatchByActionName (assocHoldingShortcut.action, shortcutStruct);
            }
            return false;
        });

    }

    public static bool dispatchByActionName (string action, ShortcutStruct shortcutStruct) {
        debug ("dispatchByActionName. assoc action: " + action +
                ", shortcutStruct: " + shortcutStruct.to_settings_string() +
                ", uistring: " + shortcutStruct.to_ui_string() +
                ", modifier: " + shortcutStruct.get_modifier_type().to_string()
                );
        switch (action) {
            case "toggleLibraryView":
                return toggleLibraryView ();
            case "moveLibraryPageBackward":
                return moveLibraryPageBackward ();
            case "moveLibraryPageForward":
                return moveLibraryPageForward ();
            case "returnToLibraryView":
                return returnToLibraryView ();
            case "movePageBackward":
                return movePageBackward ();
            case "movePageForward":
                return movePageForward ();
            case "increaseZoomLevel":
                return increaseZoomLevel ();
            case "decreaseZoomLevel":
                return decreaseZoomLevel ();
            case "toggleBookmark":
                return toggleBookmark ();
            case "unfullscreen":
                return unfullscreen ();
            case "toggleFullScreen":
                return toggleFullScreen ();
            case "closeBookwormCompletely":
                return closeBookwormCompletely ();
            case "focusOnHeaderSearchBar":
                return focusOnHeaderSearchBar ();
            default:
                return false;
        }
    }

    public static void updateShortcutAssocInSettings (ShortcutsToActionAssoc assoc) {
        BookwormApp.Settings settings = BookwormApp.Settings.get_instance ();
        BookwormApp.SettingsOfShortcuts settingsOfShortcuts = settings.shortcuts;
        string[] shortcuts_as_settings_strings = assoc.shortcuts_as_settings_strings ();
        switch (assoc.action) {
            case "toggleLibraryView":
                settingsOfShortcuts.toggle_library_view = shortcuts_as_settings_strings;
                break;
            case "moveLibraryPageBackward":
                settingsOfShortcuts.move_library_page_backward = shortcuts_as_settings_strings;
                break;
            case "moveLibraryPageForward":
                settingsOfShortcuts.move_library_page_forward = shortcuts_as_settings_strings;
                break;
            case "returnToLibraryView":
                settingsOfShortcuts.return_to_library_view = shortcuts_as_settings_strings;
                break;
            case "movePageBackward":
                settingsOfShortcuts.move_page_backward = shortcuts_as_settings_strings;
                break;
            case "movePageForward":
                settingsOfShortcuts.move_page_forward = shortcuts_as_settings_strings;
                break;
            case "increaseZoomLevel":
                settingsOfShortcuts.increase_zoom_level = shortcuts_as_settings_strings;
                break;
            case "decreaseZoomLevel":
                settingsOfShortcuts.decrease_zoom_level = shortcuts_as_settings_strings;
                break;
            case "toggleBookmark":
                settingsOfShortcuts.toggle_bookmark = shortcuts_as_settings_strings;
                break;
            case "unfullscreen":
                settingsOfShortcuts.unfullscreen = shortcuts_as_settings_strings;
                break;
            case "toggleFullScreen":
                settingsOfShortcuts.toggle_fullscreen = shortcuts_as_settings_strings;
                break;
            case "closeBookwormCompletely":
                settingsOfShortcuts.close_bookworm_completely = shortcuts_as_settings_strings;
                break;
            case "focusOnHeaderSearchBar":
                settingsOfShortcuts.focus_on_header_search_bar = shortcuts_as_settings_strings;
                break;
            default:
                break;
        }
    }

    public static bool toggleLibraryView () {
        //Keyboard shortcuts only if the current view is Library View
        if (BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[0] ||
            BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[5])
        {
            //Ctrl and V keys pressed - toggle Library View
            BookwormApp.Settings settings = BookwormApp.Settings.get_instance ();
            //if (BookwormApp.Shortcuts.isControlKeyPressed && (ev.keyval == Gdk.Key.V || ev.keyval == Gdk.Key.v)) {
                //BookwormApp.Shortcuts.isControlKeyPressed = false; //stop the action re-executing immediately
                if (settings.library_view_mode == BookwormApp.Constants.BOOKWORM_UI_STATES[5]) {
                    BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[0];
                } else {
                    BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[5];
                }
                settings.library_view_mode = BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE;
                BookwormApp.Bookworm.toggleUIState ();
            //}
            return true;
        }
        else return false;
    }

    public static bool moveLibraryPageBackward () {
        //Keyboard shortcuts only if the current view is Library View
        if (BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[0] ||
            BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[5])
        {
            //Left Arrow Key pressed : Move library page backward
            //if (ev.keyval == Gdk.Key.Left) {
                BookwormApp.AppWindow.handleLibraryPageButtons ("PREV_PAGE", true);
            //}
            return true;
        }
        else return false;
    }

    public static bool moveLibraryPageForward () {
        //Keyboard shortcuts only if the current view is Library View
        if (BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[0] ||
            BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[5])
        {
            //Right Arrow Key pressed : Move library page forward
            //if (ev.keyval == Gdk.Key.Right) {
                BookwormApp.AppWindow.handleLibraryPageButtons ("NEXT_PAGE", true);
            //}
            return true;
        }
        else return false;
    }

    public static bool returnToLibraryView () {
        //Keyboard shortcuts only if the current view is Reading View
        if (BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[1]) {
            //L Key pressed : Set action of return to Library View
            BookwormApp.Settings settings = BookwormApp.Settings.get_instance ();
            //if (BookwormApp.Shortcuts.isControlKeyPressed && (ev.keyval == Gdk.Key.L || ev.keyval == Gdk.Key.l)) {
                //Get the current scroll position of the book and add it to the book object
                BookwormApp.Bookworm.libraryViewMap.get (BookwormApp.Bookworm.locationOfEBookCurrentlyRead)
                    .setBookScrollPos (BookwormApp.contentHandler.getScrollPos ());
                //Update header to remove title of book being read
                BookwormApp.AppHeaderBar.headerbar.title = Constants.TEXT_FOR_SUBTITLE_HEADERBAR;
                //set UI in library view mode
                BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = settings.library_view_mode;
                BookwormApp.Bookworm.toggleUIState ();
            //}
            return true;
        }
        else return false;
    }

    public static bool movePageBackward () {
        //Keyboard shortcuts only if the current view is Reading View
        if (BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[1]) {
            //Left Arrow Key pressed : Move page backward
            //if (ev.keyval == Gdk.Key.Left) {
                //get object for this ebook
                BookwormApp.Book aBookLeftKeyPress = BookwormApp.Bookworm.libraryViewMap
                    .get (BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
                aBookLeftKeyPress = BookwormApp.contentHandler.renderPage (aBookLeftKeyPress, "BACKWARD");
                //update book details to libraryView Map
                BookwormApp.Bookworm.libraryViewMap.set (aBookLeftKeyPress.getBookLocation (), aBookLeftKeyPress);
            //}
            return true;
        }
        else return false;
    }

    public static bool movePageForward () {
        //Keyboard shortcuts only if the current view is Reading View
        if (BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[1]) {
            //Right Arrow Key pressed : Move page forward
            //if (ev.keyval == Gdk.Key.Right) {
                //get object for this ebook
                BookwormApp.Book aBookRightKeyPress = BookwormApp.Bookworm.libraryViewMap
                    .get (BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
                aBookRightKeyPress = BookwormApp.contentHandler.renderPage (aBookRightKeyPress, "FORWARD");
                //update book details to libraryView Map
                BookwormApp.Bookworm.libraryViewMap.set (aBookRightKeyPress.getBookLocation (), aBookRightKeyPress);
            //}
            return true;
        }
        else return false;
    }

    public static bool increaseZoomLevel () {
        //Keyboard shortcuts only if the current view is Reading View
        if (BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[1]) {
            // Control and + Key pressed : Increase Zoom level
            //if (BookwormApp.Shortcuts.isControlKeyPressed && ev.keyval == Gdk.Key.plus) {
                BookwormApp.AppWindow.aWebView.set_zoom_level (BookwormApp.AppWindow.aWebView.get_zoom_level () + BookwormApp.Constants.ZOOM_CHANGE_VALUE);
            //}
            return true;
        }
        else return false;
    }

    public static bool decreaseZoomLevel () {
        //Keyboard shortcuts only if the current view is Reading View
        if (BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[1]) {
            // Control and - Key pressed : Decrease Zoom level
            //if (BookwormApp.Shortcuts.isControlKeyPressed && ev.keyval == Gdk.Key.minus) {
                BookwormApp.AppWindow.aWebView.set_zoom_level (BookwormApp.AppWindow.aWebView.get_zoom_level () - BookwormApp.Constants.ZOOM_CHANGE_VALUE);
            //}
            return true;
        }
        else return false;
    }

    public static bool toggleBookmark () {
        //Keyboard shortcuts only if the current view is Reading View
        if (BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[1]) {
            // Control and D keys pressed - toggle bookmark
            //if (BookwormApp.Shortcuts.isControlKeyPressed && (ev.keyval == Gdk.Key.D || ev.keyval == Gdk.Key.d)) {
                //Check if bookmark for the page is not set - set bookmark
                if (BookwormApp.AppHeaderBar.bookmark_inactive_button.get_visible ()) {
                    BookwormApp.contentHandler.handleBookMark ("INACTIVE_CLICKED");
                    //BookwormApp.Shortcuts.isControlKeyPressed = false; //stop the action re-executing immediately
                } else {
                    //Bookmark for the page is set - unset bookmark
                    BookwormApp.contentHandler.handleBookMark ("ACTIVE_CLICKED");
                    //BookwormApp.Shortcuts.isControlKeyPressed = false; //stop the action re-executing immediately
                }
            //}
            return true;
        }
        else return false;
    }

    public static bool unfullscreen () {
        //Escape key pressed: remove full screen
        //if (ev.keyval == Gdk.Key.Escape) {
            BookwormApp.AppWindow.book_reading_footer_box.show ();
            BookwormApp.Bookworm.window.unfullscreen ();
        //}
        return true;
    }

    public static bool toggleFullScreen () {
        //F11 key pressed: toggle full screen
        //if (ev.keyval == Gdk.Key.F11) {
            BookwormApp.Settings settings = BookwormApp.Settings.get_instance ();
            if (settings.is_fullscreen) {
                BookwormApp.AppWindow.book_reading_footer_box.show ();
                BookwormApp.Bookworm.window.unfullscreen ();
            } else {
                BookwormApp.AppWindow.book_reading_footer_box.hide ();
                BookwormApp.Bookworm.window.fullscreen ();
            }
            return true;
        //}
    }

    public static bool closeBookwormCompletely () {
        //Ctrl+Q Key pressed: Close Bookworm completely
        //if (BookwormApp.Shortcuts.isControlKeyPressed && (ev.keyval == Gdk.Key.Q || ev.keyval == Gdk.Key.q)) {
            BookwormApp.Bookworm.window.destroy ();
        //}
        return true;
    }

    public static bool focusOnHeaderSearchBar () {
        //Ctrl+F Key pressed: Focus the search entry on the header
        //if (BookwormApp.Shortcuts.isControlKeyPressed && (ev.keyval == Gdk.Key.F || ev.keyval == Gdk.Key.f)) {
            BookwormApp.AppHeaderBar.headerSearchBar.grab_focus ();
        //}
        return true;
    }

}

public class BookwormApp.ShortcutsAssocsHolder {

    public delegate void AssocWithIndexHandler (ShortcutsToActionAssoc assoc, int assoc_index);
    public delegate void AssocHandler (ShortcutsToActionAssoc assoc);

    private static ShortcutsToActionAssoc[] readAssocsFromSettings () {
        BookwormApp.Settings settings = BookwormApp.Settings.get_instance ();
        BookwormApp.SettingsOfShortcuts settingsOfShortcuts = settings.shortcuts;

        // toggleLibraryView
        // moveLibraryPageBackward
        // moveLibraryPageForward
        // returnToLibraryView
        // movePageBackward
        // movePageForward
        // increaseZoomLevel
        // decreaseZoomLevel
        // toggleBookmark
        // unfullscreen
        // toggleFullScreen
        // closeBookwormCompletely
        // focusOnHeaderSearchBar

        var toggleLibraryView = ShortcutsToActionAssoc.fromShortcutsStringsArray (settingsOfShortcuts.toggle_library_view, "toggleLibraryView", ShortcutGroup.LIBRARY_VIEW_GROUP);
        var moveLibraryPageBackward = ShortcutsToActionAssoc.fromShortcutsStringsArray (settingsOfShortcuts.move_library_page_backward, "moveLibraryPageBackward", ShortcutGroup.LIBRARY_VIEW_GROUP);
        var moveLibraryPageForward = ShortcutsToActionAssoc.fromShortcutsStringsArray (settingsOfShortcuts.move_library_page_forward, "moveLibraryPageForward", ShortcutGroup.LIBRARY_VIEW_GROUP);
        var returnToLibraryView = ShortcutsToActionAssoc.fromShortcutsStringsArray (settingsOfShortcuts.return_to_library_view, "returnToLibraryView", ShortcutGroup.READING_VIEW_GROUP);
        var movePageBackward = ShortcutsToActionAssoc.fromShortcutsStringsArray (settingsOfShortcuts.move_page_backward, "movePageBackward", ShortcutGroup.READING_VIEW_GROUP);
        var movePageForward = ShortcutsToActionAssoc.fromShortcutsStringsArray (settingsOfShortcuts.move_page_forward, "movePageForward", ShortcutGroup.READING_VIEW_GROUP);
        var increaseZoomLevel = ShortcutsToActionAssoc.fromShortcutsStringsArray (settingsOfShortcuts.increase_zoom_level, "increaseZoomLevel", ShortcutGroup.READING_VIEW_GROUP);
        var decreaseZoomLevel = ShortcutsToActionAssoc.fromShortcutsStringsArray (settingsOfShortcuts.decrease_zoom_level, "decreaseZoomLevel", ShortcutGroup.READING_VIEW_GROUP);
        var toggleBookmark = ShortcutsToActionAssoc.fromShortcutsStringsArray (settingsOfShortcuts.toggle_bookmark, "toggleBookmark", ShortcutGroup.READING_VIEW_GROUP);
        var unfullscreen = ShortcutsToActionAssoc.fromShortcutsStringsArray (settingsOfShortcuts.unfullscreen, "unfullscreen", ShortcutGroup.ALL);
        var toggleFullScreen = ShortcutsToActionAssoc.fromShortcutsStringsArray (settingsOfShortcuts.toggle_fullscreen, "toggleFullScreen", ShortcutGroup.ALL);
        var closeBookwormCompletely = ShortcutsToActionAssoc.fromShortcutsStringsArray (settingsOfShortcuts.close_bookworm_completely, "closeBookwormCompletely", ShortcutGroup.ALL);
        var focusOnHeaderSearchBar = ShortcutsToActionAssoc.fromShortcutsStringsArray (settingsOfShortcuts.focus_on_header_search_bar, "focusOnHeaderSearchBar", ShortcutGroup.ALL);

        return {
            toggleLibraryView,
            moveLibraryPageBackward,
            moveLibraryPageForward,
            returnToLibraryView,
            movePageBackward,
            movePageForward,
            increaseZoomLevel,
            decreaseZoomLevel,
            toggleBookmark,
            unfullscreen,
            toggleFullScreen,
            closeBookwormCompletely,
            focusOnHeaderSearchBar
        };
    }

    public static ShortcutsAssocsHolder readFromSettings () {
        var assocs = ShortcutsAssocsHolder.readAssocsFromSettings ();
        return new ShortcutsAssocsHolder (assocs);
    }

    private ArrayList<ShortcutsToActionAssoc> assocs;

    private ShortcutsAssocsHolder (ShortcutsToActionAssoc[] assocs) {

        this.assocs = new ArrayList<ShortcutsToActionAssoc> ();

        this.assocs.add_all_array (assocs);

        foreach (var assoc in this.assocs) {
            assoc.shortcutsChanged.connect ((isSameAsSettingsNow) => {
                if (!isSameAsSettingsNow) {
                    this.stateChanged (false);
                } else {
                    this.stateChanged (this.assocs.all_match ((assoc) => assoc.isSameAsSettings));
                }
            });
        }
    }

    public signal void stateChanged (bool isSameAsSettingsNow);

    public ShortcutsToActionAssoc? findAssoc (Predicate<ShortcutsToActionAssoc> predicate) {
        return this.assocs.first_match (predicate);
        /*
        foreach (ShortcutsToActionAssoc assoc in this.assocs) {
            if (predicate (assoc)) return assoc;
        }
        return null;
        */
    }

    public bool containsAssocMatching (Predicate<ShortcutsToActionAssoc> predicate) {
        return this.assocs.any_match (predicate);
    }

    public void foreachAssocWithIndex (AssocWithIndexHandler handler) {
        for (int index = 0; index < assocs.size; index++) {
            var assoc = assocs[index];
            handler (assoc, index);
        }
    }

    public void foreachAssoc (AssocHandler handler) {
        for (int index = 0; index < assocs.size; index++) {
            var assoc = assocs[index];
            handler (assoc);
        }
    }

    public void foreachFilteredAssocWithIndex (Predicate<ShortcutsToActionAssoc> predicate, AssocWithIndexHandler handler) {
        int filteredIndex = 0;
        for (int index = 0; index < assocs.size; index++) {
            var assoc = assocs[index];
            if (predicate (assoc)) {
                handler (assoc, filteredIndex);
                filteredIndex++;
            }
        }
    }

    public void foreachFilteredAssoc (Predicate<ShortcutsToActionAssoc> predicate, AssocHandler handler) {
        for (int index = 0; index < assocs.size; index++) {
            var assoc = assocs[index];
            if (predicate (assoc)) {
                handler (assoc);
            }
        }
    }

    public int assocsCount () {
        return assocs.size;
    }
}

public enum BookwormApp.ShortcutGroup {
    LIBRARY_VIEW_GROUP = 1 << 0,
    READING_VIEW_GROUP = 1 << 1,
    ALL = (1 << 0) | (1 << 1);

    public string to_string () {
        switch (this) {
            case LIBRARY_VIEW_GROUP:
                return "library view";
            case READING_VIEW_GROUP:
                return "reading view";
            case ALL:
                return "all views";
            default:
                assert_not_reached ();
        }
    }
}

public class BookwormApp.ShortcutsToActionAssoc {

    public delegate void ShortcutHandler (ShortcutStruct shortcutStruct);

    private ArrayList<ShortcutStruct> originalShortcuts;
    private ArrayList<ShortcutStruct> shortcutsToAdd = new ArrayList<ShortcutStruct> (ShortcutStruct.are_equal);
    private ArrayList<ShortcutStruct> shortcutsToRemove = new ArrayList<ShortcutStruct> (ShortcutStruct.are_equal);

    private ArrayList<ShortcutStruct> shortcuts {
        owned get {
            var result = new ArrayList<ShortcutStruct> (ShortcutStruct.are_equal);
            result.add_all (originalShortcuts);
            result.remove_all (shortcutsToRemove);
            result.add_all (shortcutsToAdd);
            return result;
        }
    }

    private string _action;
    public string action {
        get {
            return _action;
        }
    }

    private ShortcutGroup _shortcutGroup;
    public ShortcutGroup shortcutGroup {
        get {
            return _shortcutGroup;
        }
    }

    public bool isSameAsSettings {
        get {
            return this.shortcutsToAdd.is_empty &&
                this.shortcutsToRemove.is_empty;
        }
    }

    public ShortcutsToActionAssoc(ArrayList<ShortcutStruct> shortcuts, string action, ShortcutGroup shortcutGroup) {
        this.originalShortcuts = shortcuts;
        this._action = action;
        this._shortcutGroup = shortcutGroup;
    }

    public signal void shortcutsChanged (bool isSameAsSettingsNow);

    public void discardChanges () {
        this.shortcutsToRemove.clear ();
        this.shortcutsToAdd.clear ();
    }

    public void saveChanges () {
        this.originalShortcuts.remove_all (this.shortcutsToRemove);
        this.originalShortcuts.add_all (this.shortcutsToAdd);
        this.shortcutsToRemove.clear ();
        this.shortcutsToAdd.clear ();
    }

    public ArrayList<ShortcutStruct> getOldShortcuts () {
        var result = new ArrayList<ShortcutStruct> (ShortcutStruct.are_equal);
        result.add_all (originalShortcuts);
        return result;
    }

    public string[] shortcuts_as_settings_strings () {
        string[] arr = new string[shortcuts.size];
        for (int ind = 0; ind < shortcuts.size; ind++) {
            arr[ind] = shortcuts.get (ind).to_settings_string ();
        }
        return arr;
    }

    public void foreachShortcut (ShortcutHandler handler) {
        foreach (var shortcut in this.shortcuts) {
            handler (shortcut);
        }
    }

    public bool containsShortcut (ShortcutStruct shortcutStruct) {
        return this.shortcuts.contains (shortcutStruct);
    }

    public void addShortcut (ShortcutStruct shortcutStruct) {
        if (!this.shortcutsToRemove.remove (shortcutStruct)) {
            this.shortcutsToAdd.add (shortcutStruct);
        }
        this.shortcutsChanged (this.isSameAsSettings);
    }

    public void removeShortcut (ShortcutStruct shortcutStruct) {
        if (!this.shortcutsToAdd.remove (shortcutStruct)) {
            this.shortcutsToRemove.add (shortcutStruct);
        }
        this.shortcutsChanged (this.isSameAsSettings);
    }

    public static ShortcutsToActionAssoc fromSingleShortcut(ShortcutStruct singleShortcut, string action, ShortcutGroup shortcutGroup) {
        var shortcuts = new ArrayList<ShortcutStruct> (ShortcutStruct.are_equal);
        shortcuts.add (singleShortcut);
        return new ShortcutsToActionAssoc (shortcuts, action, shortcutGroup);
    }

    public static ShortcutsToActionAssoc fromShortcutsStringsArray(string[] shortcutsArray, string action, ShortcutGroup shortcutGroup) {
        var shortcuts = new ArrayList<ShortcutStruct> (ShortcutStruct.are_equal);
        foreach (string shortcut in shortcutsArray) {
            var shortcutStruct = ShortcutStruct.parse (shortcut);
            if (shortcutStruct != null) {
                shortcuts.add (shortcutStruct);
            }
        }
        return new ShortcutsToActionAssoc (shortcuts, action, shortcutGroup);
    }

    public static ShortcutsToActionAssoc fromShortcutsArray(ShortcutStruct[] shortcutsArray, string action, ShortcutGroup shortcutGroup) {
        var shortcuts = new ArrayList<ShortcutStruct> (ShortcutStruct.are_equal);
        foreach (ShortcutStruct shortcut in shortcutsArray) {
            shortcuts.add (shortcut);
        }
        return new ShortcutsToActionAssoc (shortcuts, action, shortcutGroup);
    }
}

public class BookwormApp.ShortcutStruct {

    public uint keyval;
    public int modifiers_state;

    public static ShortcutStruct null () {
        return new ShortcutStruct (-1, -1);
    }

    public static bool isNull (ShortcutStruct shortcutStruct) {
        return shortcutStruct.keyval == -1 && shortcutStruct.modifiers_state == -1;
    }

    public static ShortcutStruct? parse (string str) {
        if (str.size () == 0) {
            return null;
        }

        var splitted = str.split (" ", 2);

        if (splitted.length != 2) {
            return null;
        }
        var keyval_name = splitted[0];
        uint keyval = Gdk.keyval_from_name (keyval_name);
        var after_whitespace = splitted[1];
        int modifiers_state;
        /*
        var parsed_modifiers_state = int.try_parse (after_whitespace, modifiers_state);
        if (!parsed_modifiers_state) {
            return null;
        }
        */
        modifiers_state = int.parse (after_whitespace); // TODO handle parsing error
        return new ShortcutStruct (keyval, modifiers_state);
    }

    public static bool are_equal (ShortcutStruct a, ShortcutStruct b) {
        bool result = (a.keyval == b.keyval) && (a.modifiers_state == b.modifiers_state);
        debug ("are_equal: " + result.to_string() + " a: " + a.to_settings_string() + ", b: " + b.to_settings_string());
        return result;
    }

    public ShortcutStruct (uint keyval, int modifiers_state) {
        this.keyval = keyval;
        this.modifiers_state = modifiers_state;
    }

    public Gdk.ModifierType get_modifier_type () {

        var isControl = (this.modifiers_state & Gdk.ModifierType.CONTROL_MASK) != 0;
        var isAlt = (this.modifiers_state & Gdk.ModifierType.MOD1_MASK) != 0;
        var isShift = (this.modifiers_state & Gdk.ModifierType.SHIFT_MASK) != 0;

        Gdk.ModifierType result = (Gdk.ModifierType) 0;

        /*
        if (isControl) {
            result = Gdk.ModifierType.CONTROL_MASK;
        }
        if (isAlt) {
            result = Gdk.ModifierType.MOD1_MASK;
        }
        if (isShift) {
            result = Gdk.ModifierType.SHIFT_MASK;
        }
        */


        if (isControl) {
            result = result | Gdk.ModifierType.CONTROL_MASK;
        }
        if (isAlt) {
            result = result | Gdk.ModifierType.MOD1_MASK;
        }
        if (isShift) {
            result = result | Gdk.ModifierType.SHIFT_MASK;
        }
        return result;
    }

    public string to_settings_string () {
        return Gdk.keyval_name (this.keyval) + " " + this.modifiers_state.to_string ();
    }

    public string to_ui_string () {
        string keyval_str;
        unichar unicode_keyval = Gdk.keyval_to_unicode (this.keyval);
        if (unicode_keyval.validate() && unicode_keyval.isgraph()) {
            keyval_str = unicode_keyval.to_string();
        } else {
            keyval_str = Gdk.keyval_name (this.keyval);
        }
        var isControl = (this.modifiers_state & Gdk.ModifierType.CONTROL_MASK) != 0;
        var isAlt = (this.modifiers_state & Gdk.ModifierType.MOD1_MASK) != 0;
        var isShift = (this.modifiers_state & Gdk.ModifierType.SHIFT_MASK) != 0;
        string whetherShiftStr = "";
        if (isShift) {
            whetherShiftStr = "<shift>";
        }
        string whetherControlStr = "";
        if (isControl) {
            whetherControlStr = "<control>";
        }
        string whetherAltStr = "";
        if (isAlt) {
            whetherAltStr = "<alt>";
        }
        string result = whetherControlStr + whetherAltStr + whetherShiftStr + " " + keyval_str;
        return result;
    }

}
