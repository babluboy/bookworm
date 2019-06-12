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

public class BookwormApp.Shortcuts: Gtk.Widget {
  public static bool isControlKeyPressed = false;
  public static BookwormApp.Settings settings;

  public static bool handleKeyPress(Gdk.EventKey ev){
    settings = BookwormApp.Settings.get_instance();
    //Ctrl Key pressed: Record the action for Ctrl combination keys
    if ((ev.keyval == Gdk.Key.Control_L || ev.keyval == Gdk.Key.Control_R)) {
      BookwormApp.Shortcuts.isControlKeyPressed = true;
    }
    //Keyboard shortcuts only if the current view is Library View
    if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[0] ||
       BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[5]){
      //Ctrl and V keys pressed - toggle Library View
      if (BookwormApp.Shortcuts.isControlKeyPressed && (ev.keyval == Gdk.Key.V || ev.keyval == Gdk.Key.v)){
        BookwormApp.Shortcuts.isControlKeyPressed = false; //stop the action re-executing immediately
        if(settings.library_view_mode == BookwormApp.Constants.BOOKWORM_UI_STATES[5]){
          BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[0];
        }else{
          BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[5];
        }
        settings.library_view_mode = BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE;
        BookwormApp.Bookworm.toggleUIState();
      }
      //Left Arrow Key pressed : Move library page backward
      if (ev.keyval == Gdk.Key.Left) {
            BookwormApp.AppWindow.handleLibraryPageButtons("PREV_PAGE");
      }
      //Right Arrow Key pressed : Move library page forward
      if (ev.keyval == Gdk.Key.Right) {
            BookwormApp.AppWindow.handleLibraryPageButtons("NEXT_PAGE");
      }
    }
    //Keyboard shortcuts only if the current view is Reading View
    if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[1]){
      //L Key pressed : Set action of return to Library View
      if (BookwormApp.Shortcuts.isControlKeyPressed && (ev.keyval == Gdk.Key.L || ev.keyval == Gdk.Key.l)) {
        //Get the current scroll position of the book and add it to the book object
        (BookwormApp.Bookworm.libraryViewMap.get(
                BookwormApp.Bookworm.locationOfEBookCurrentlyRead
        )).setBookScrollPos(BookwormApp.contentHandler.getScrollPos());
        //Update header to remove title of book being read
        BookwormApp.AppHeaderBar.headerbar.title = Constants.TEXT_FOR_SUBTITLE_HEADERBAR;
        //set UI in library view mode
        BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = settings.library_view_mode;
        BookwormApp.Bookworm.toggleUIState();
      }
      //Left Arrow Key pressed : Move page backward
      if (ev.keyval == Gdk.Key.Left) {
        //get object for this ebook
        BookwormApp.Book aBookLeftKeyPress = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
        aBookLeftKeyPress = BookwormApp.contentHandler.renderPage(aBookLeftKeyPress, "BACKWARD");
        //update book details to libraryView Map
        BookwormApp.Bookworm.libraryViewMap.set(aBookLeftKeyPress.getBookLocation(), aBookLeftKeyPress);
      }
      //Right Arrow Key pressed : Move page forward
      if (ev.keyval == Gdk.Key.Right) {
        //get object for this ebook
        BookwormApp.Book aBookRightKeyPress = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);
        aBookRightKeyPress = BookwormApp.contentHandler.renderPage(aBookRightKeyPress, "FORWARD");
        //update book details to libraryView Map
        BookwormApp.Bookworm.libraryViewMap.set(aBookRightKeyPress.getBookLocation(), aBookRightKeyPress);
      }
      // Control and + Key pressed : Increase Zoom level
      if (BookwormApp.Shortcuts.isControlKeyPressed && ev.keyval == Gdk.Key.plus){
        BookwormApp.AppWindow.aWebView.set_zoom_level (BookwormApp.AppWindow.aWebView.get_zoom_level() + BookwormApp.Constants.ZOOM_CHANGE_VALUE);
      }
      // Control and - Key pressed : Decrease Zoom level
      if (BookwormApp.Shortcuts.isControlKeyPressed && ev.keyval == Gdk.Key.minus){
        BookwormApp.AppWindow.aWebView.set_zoom_level (BookwormApp.AppWindow.aWebView.get_zoom_level() - BookwormApp.Constants.ZOOM_CHANGE_VALUE);
      }
      // Control and D keys pressed - toggle bookmark
      if (BookwormApp.Shortcuts.isControlKeyPressed && (ev.keyval == Gdk.Key.D || ev.keyval == Gdk.Key.d)){
        //Check if bookmark for the page is not set - set bookmark
        if(BookwormApp.AppHeaderBar.bookmark_inactive_button.get_visible()){
          BookwormApp.contentHandler.handleBookMark("INACTIVE_CLICKED");
          BookwormApp.Shortcuts.isControlKeyPressed = false; //stop the action re-executing immediately
        }else{
          //Bookmark for the page is set - unset bookmark
          BookwormApp.contentHandler.handleBookMark("ACTIVE_CLICKED");
          BookwormApp.Shortcuts.isControlKeyPressed = false; //stop the action re-executing immediately
        }
      }
    }

    //Escape key pressed: remove full screen
    if (ev.keyval == Gdk.Key.Escape) {
      BookwormApp.AppWindow.book_reading_footer_box.show();
      BookwormApp.Bookworm.window.unfullscreen();
    }
    //F11 key pressed: toggle full screen
    if (ev.keyval == Gdk.Key.F11) {
      if (settings.is_fullscreen) {
        BookwormApp.AppWindow.book_reading_footer_box.show();
        BookwormApp.Bookworm.window.unfullscreen();
      }else{
        BookwormApp.AppWindow.book_reading_footer_box.hide();
        BookwormApp.Bookworm.window.fullscreen();
      }
      return true;
    }
    //Ctrl+Q Key pressed: Close Bookworm completely
    if (BookwormApp.Shortcuts.isControlKeyPressed && (ev.keyval == Gdk.Key.Q || ev.keyval == Gdk.Key.q)) {
      BookwormApp.Bookworm.window.destroy();
    }
    //Ctrl+F Key pressed: Focus the search entry on the header
    if (BookwormApp.Shortcuts.isControlKeyPressed && (ev.keyval == Gdk.Key.F || ev.keyval == Gdk.Key.f)) {
      BookwormApp.AppHeaderBar.headerSearchBar.grab_focus ();
    }
    return false;
  }

  public static bool handleKeyRelease(Gdk.EventKey ev){
    //Ctrl Key released: Record the action for Ctrl combination keys
    if ((ev.keyval == Gdk.Key.Control_L || ev.keyval == Gdk.Key.Control_R)) {
      BookwormApp.Shortcuts.isControlKeyPressed = false;
    }
    return false;
  }
}
