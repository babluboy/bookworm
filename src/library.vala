/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and manages the library and
* views associated with the library
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
public class BookwormApp.Library{

  public static void updateLibraryView(owned BookwormApp.Book aBook){
		debug("Started updating Library View for book:"+aBook.getBookLocation());

		Gtk.Image aCoverImage;
    Gtk.Label titleTextLabel = new Gtk.Label("");
    Gtk.Image bookSelectionImage;
    Gtk.Image bookSelectedImage;
		string bookCoverLocation;

    Gdk.Pixbuf bookPlaceholderCoverPix = new Gdk.Pixbuf.from_file_at_scale(BookwormApp.Constants.PLACEHOLDER_COVER_IMAGE_LOCATION, 150, 200, false);
    Gtk.Image bookPlaceholderCoverImage = new Gtk.Image.from_pixbuf(bookPlaceholderCoverPix);

		//Add a default cover selected at random if no cover exists
		if(aBook.getBookCoverLocation() == null || aBook.getBookCoverLocation().length < 1) {
			//default Book Cover Image not set - select at random from the default covers
			bookCoverLocation = BookwormApp.Constants.DEFAULT_COVER_IMAGE_LOCATION.replace("N", GLib.Random.int_range(1, 6).to_string());
			aBook.setBookCoverLocation(bookCoverLocation);
		}
		Gdk.Pixbuf aBookCover = new Gdk.Pixbuf.from_file_at_scale(aBook.getBookCoverLocation(), 150, 200, false);
		aCoverImage = new Gtk.Image.from_pixbuf(aBookCover);
		aCoverImage.set_halign(Align.START);
		aCoverImage.set_valign(Align.START);

    //Add title of the book if Default Cover is being used
    if(!aBook.getIsBookCoverImagePresent()){
			titleTextLabel.set_text("<b>"+aBook.getBookTitle()+"</b>");
			titleTextLabel.set_xalign(0.0f);
			titleTextLabel.set_use_markup (true);
			titleTextLabel.set_line_wrap (true);
      titleTextLabel.set_margin_start(BookwormApp.Constants.SPACING_WIDGETS);
      titleTextLabel.set_margin_end(BookwormApp.Constants.SPACING_WIDGETS);
      titleTextLabel.set_max_width_chars(-1);
    }
    //Add selection option badge to the book for later use - add it below the cover to hide it
    Gdk.Pixbuf bookSelectionPix = new Gdk.Pixbuf.from_file(BookwormApp.Constants.SELECTION_OPTION_IMAGE_LOCATION);
    bookSelectionImage = new Gtk.Image.from_pixbuf(bookSelectionPix);
    bookSelectionImage.set_halign(Align.START);
    bookSelectionImage.set_valign(Align.START);

    //Add selection checked badge to the book for later use
    Gdk.Pixbuf bookSelectedPix = new Gdk.Pixbuf.from_file(BookwormApp.Constants.SELECTION_CHECKED_IMAGE_LOCATION);
    bookSelectedImage = new Gtk.Image.from_pixbuf(bookSelectedPix);
    bookSelectedImage.set_halign(Align.START);
    bookSelectedImage.set_valign(Align.START);

    //Create a Overlay to hold the images in the right order
    Gtk.Overlay aOverlayImage = new Gtk.Overlay();
    aOverlayImage.add(bookPlaceholderCoverImage);
    aOverlayImage.add_overlay(bookSelectionImage);
    aOverlayImage.add_overlay(bookSelectedImage);
    aOverlayImage.add_overlay(aCoverImage);
    aOverlayImage.add_overlay(titleTextLabel);

    //Add the overlaid images to a EventBox to allow mouse click actions to be captures
    Gtk.EventBox aEventBox = new Gtk.EventBox();
		aEventBox.set_name(aBook.getBookLocation());
    aEventBox.add(aOverlayImage);

		//register the book with the filter function
		BookwormApp.Bookworm.libraryViewFilter((Gtk.FlowBoxChild)aEventBox);
		//add the book to the library view
		BookwormApp.AppWindow.library_grid.add (aEventBox);

		//set gtk widgets into the Book object for later manipulation
    aBook.setBookWidgetList(bookPlaceholderCoverImage); //position=0
    aBook.setBookWidgetList(aCoverImage);               //position=1
    aBook.setBookWidgetList(titleTextLabel);            //position=2
    aBook.setBookWidgetList(bookSelectedImage);         //position=3
    aBook.setBookWidgetList(bookSelectionImage);        //position=4
    aBook.setBookWidgetList(aEventBox);                 //position=5
    aBook.setBookWidgetList(aOverlayImage);             //position=6

		//set the view mode to library view
		BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[0];
		BookwormApp.AppWindow.library_grid.show_all();
		BookwormApp.Bookworm.toggleUIState();

		//add listener for book objects based on mode
		aEventBox.button_press_event.connect (() => {
			if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[0]){
				aBook  = BookwormApp.Bookworm.libraryViewMap.get(aEventBox.get_name());
				debug("Initiated process for reading eBook:"+aBook.getBookLocation());
				BookwormApp.Bookworm.readSelectedBook(aBook);
			}
			if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[2] ||
         BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[3]){
				BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[3];
				aBook  = BookwormApp.Bookworm.libraryViewMap.get(aEventBox.get_name());
				updateLibraryViewForSelectionMode(aBook);
			}
			return true;
		});
		//add book details to libraryView Map
		BookwormApp.Bookworm.libraryViewMap.set(aBook.getBookLocation(), aBook);
    debug("Completed updating Library View for book:"+aBook.getBookLocation());
	}

  public static void updateLibraryViewForSelectionMode(owned BookwormApp.Book? lBook){
		if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[0]){
      debug ("Updating Library View for Selection Badges BOOKWORM_UI_STATES[0]");
			//loop over HashMap of Book Objects and overlay selection image
			foreach (BookwormApp.Book book in BookwormApp.Bookworm.libraryViewMap.values){
				if(book.getBookWidgetList() != null && book.getBookWidgetList().size > 3){
  				Gtk.Overlay aOverlayImage = (Gtk.Overlay) book.getBookWidgetList().get(6);
          //set the order of the widgets to put the selection/selected badges at bottom
          aOverlayImage.reorder_overlay(book.getBookWidgetList().get(4), 1);
          aOverlayImage.reorder_overlay(book.getBookWidgetList().get(3), 2);
          aOverlayImage.reorder_overlay(book.getBookWidgetList().get(1), 3);
          aOverlayImage.reorder_overlay(book.getBookWidgetList().get(2), 4);
        }
      }
		}
		if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[2]){
      debug ("Updating Library View for Selection Badges BOOKWORM_UI_STATES[2]");
			//loop over HashMap of Book Objects and overlay selection badge
			foreach (BookwormApp.Book book in BookwormApp.Bookworm.libraryViewMap.values){
        if(book.getBookWidgetList() != null && book.getBookWidgetList().size > 3){
          Gtk.Overlay aOverlayImage = (Gtk.Overlay) book.getBookWidgetList().get(6);
          //set the order of the widgets to put the selection badge on top
          aOverlayImage.reorder_overlay(book.getBookWidgetList().get(3), 1);
          aOverlayImage.reorder_overlay(book.getBookWidgetList().get(1), 2);
          aOverlayImage.reorder_overlay(book.getBookWidgetList().get(2), 3);
          aOverlayImage.reorder_overlay(book.getBookWidgetList().get(4), 4);
        }
			}
		}
		if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[3]){
      debug ("Updating Library View for Selection Badges BOOKWORM_UI_STATES[3]");
      if(lBook != null){
        Gtk.Overlay aOverlayImage = (Gtk.Overlay) lBook.getBookWidgetList().get(6);
        if(!lBook.getIsBookSelected()){
          if(lBook.getBookWidgetList() != null && lBook.getBookWidgetList().size > 3){
            //set the order of the widgets to put the selected badge on top
            aOverlayImage.reorder_overlay(lBook.getBookWidgetList().get(4), 1);
            aOverlayImage.reorder_overlay(lBook.getBookWidgetList().get(1), 2);
            aOverlayImage.reorder_overlay(lBook.getBookWidgetList().get(2), 3);
            aOverlayImage.reorder_overlay(lBook.getBookWidgetList().get(3), 4);
          }
          lBook.setIsBookSelected(true);
        }else{
          if(lBook.getBookWidgetList() != null && lBook.getBookWidgetList().size > 3){
            //set the order of the widgets to put the selection badge on top
            aOverlayImage.reorder_overlay(lBook.getBookWidgetList().get(3), 1);
            aOverlayImage.reorder_overlay(lBook.getBookWidgetList().get(1), 2);
            aOverlayImage.reorder_overlay(lBook.getBookWidgetList().get(2), 3);
            aOverlayImage.reorder_overlay(lBook.getBookWidgetList().get(4), 4);
          }
          lBook.setIsBookSelected(false);
        }
        //update the book into the Library view HashMap
        BookwormApp.Bookworm.libraryViewMap.set(lBook.getBookLocation(),lBook);
      }
		}

		BookwormApp.AppWindow.library_grid.show_all();
		BookwormApp.Bookworm.toggleUIState();
	}
}
