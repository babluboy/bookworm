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
    updateLibraryListView(aBook);
    updateLibraryGridView(aBook);
  }

  public static void updateLibraryListView(owned BookwormApp.Book aBook){
    debug("Started updating Library List View for book:"+aBook.getBookLocation());
    Gdk.Pixbuf image_rating;
    switch (aBook.getBookRating().to_string()){
      case "1":
        image_rating = BookwormApp.Bookworm.image_rating_1;
        break;
      case "2":
        image_rating = BookwormApp.Bookworm.image_rating_2;
        break;
      case "3":
        image_rating = BookwormApp.Bookworm.image_rating_3;
        break;
      case "4":
        image_rating = BookwormApp.Bookworm.image_rating_4;
        break;
      case "5":
        image_rating = BookwormApp.Bookworm.image_rating_5;
        break;
      default:
        image_rating = null;
        break;
    }
    BookwormApp.AppWindow.library_table_liststore.append (out BookwormApp.AppWindow.library_table_iter);
		BookwormApp.AppWindow.library_table_liststore.set (BookwormApp.AppWindow.library_table_iter,
                            0, aBook.getBookLocation(),
                            1, BookwormApp.Utils.parseMarkUp(aBook.getBookTitle()),
                            2, aBook.getBookAuthor(),
                            3, new DateTime.from_unix_local(int64.parse(aBook.getBookLastModificationDate())).format("%Y-%m-%d %H:%M:%S "),
                            4, image_rating,
                            5, aBook.getBookTags()
                          );
    //add book details to libraryView Map
		BookwormApp.Bookworm.libraryViewMap.set(aBook.getBookLocation(), aBook);
    BookwormApp.Bookworm.libraryTreeModelFilter = new Gtk.TreeModelFilter (BookwormApp.AppWindow.library_table_liststore, null);
    setFilterAndSort(BookwormApp.AppWindow.library_table_treeview, BookwormApp.Bookworm.libraryTreeModelFilter, SortType.DESCENDING);
  }

  public static void updateLibraryGridView(owned BookwormApp.Book aBook){
		debug("Started updating Library Grid View for book:"+aBook.getBookLocation());
		Gtk.Image aCoverImage;
    Gtk.Label titleTextLabel = new Gtk.Label("");
    Gtk.Image bookSelectionImage;
    Gtk.Image bookSelectedImage;
		string bookCoverLocation;
    Gdk.Pixbuf aBookCover;
    Gdk.Pixbuf bookPlaceholderCoverPix = new Gdk.Pixbuf.from_file_at_scale(BookwormApp.Constants.PLACEHOLDER_COVER_IMAGE_LOCATION, 150, 200, false);
    Gtk.Image bookPlaceholderCoverImage = new Gtk.Image.from_pixbuf(bookPlaceholderCoverPix);

		//Add a default cover selected at random if no cover exists
		if(aBook.getBookCoverLocation() == null || aBook.getBookCoverLocation().length < 1) {
			//default Book Cover Image not set - select at random from the default covers
			bookCoverLocation = BookwormApp.Constants.DEFAULT_COVER_IMAGE_LOCATION.replace("N", GLib.Random.int_range(1, 6).to_string());
			aBook.setBookCoverLocation(bookCoverLocation);
		}
    try{
		    aBookCover = new Gdk.Pixbuf.from_file_at_scale(aBook.getBookCoverLocation(), 150, 200, false);
        aCoverImage = new Gtk.Image.from_pixbuf(aBookCover);
    }catch(GLib.Error e){
      //Sometimes the path to the image selected by the parser is not a image
      //This catch block assigns a default cover selected at random to cover this issue
      bookCoverLocation = BookwormApp.Constants.DEFAULT_COVER_IMAGE_LOCATION.replace("N", GLib.Random.int_range(1, 6).to_string());
			aBook.setBookCoverLocation(bookCoverLocation);
      aBookCover = new Gdk.Pixbuf.from_file_at_scale(aBook.getBookCoverLocation(), 150, 200, false);
      aCoverImage = new Gtk.Image.from_pixbuf(aBookCover);
      //set cover image present flag to false - this will add title text to the default cover
      aBook.setIsBookCoverImagePresent(false);
    }

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
    }else{
      //remove the title label if the book has a cover image available
      titleTextLabel.set_text("");
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
		libraryViewFilter((Gtk.FlowBoxChild)aEventBox);
		//add the book to the library view
		BookwormApp.AppWindow.library_grid.add (aEventBox);

		//set gtk widgets into the Book object for later manipulation
    aBook.setBookWidget("PLACEHOLDER_COVER_IMAGE", bookPlaceholderCoverImage);
    aBook.setBookWidget("COVER_IMAGE", aCoverImage);
    aBook.setBookWidget("TITLE_TEXT_LABEL", titleTextLabel);
    aBook.setBookWidget("SELECTED_BADGE_IMAGE", bookSelectedImage);
    aBook.setBookWidget("SELECTION_BADGE_IMAGE", bookSelectionImage);
    aBook.setBookWidget("BOOK_EVENTBOX", aEventBox);
    aBook.setBookWidget("BOOK_OVERLAY_IMAGE", aOverlayImage);

    //Create a popover context menu for the book
    Gtk.Popover bookPopover = BookwormApp.AppDialog.createBookContextMenu(aBook);

		//set the view mode to library view
		BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[0];
		BookwormApp.AppWindow.library_grid.show_all();
		BookwormApp.Bookworm.toggleUIState();

		//add listener for book objects based on mode
		aEventBox.button_press_event.connect ((event) => {
      //capture which mouse button was clicked on the book in the library
      uint mouseButtonClicked;
      event.get_button(out mouseButtonClicked);
      //handle right button click for context menu
      if (event.get_event_type ()  == Gdk.EventType.BUTTON_PRESS  &&  mouseButtonClicked == 3){
        bookPopover.set_visible (true);
        bookPopover.show_all();
        return true;
      }else{
        //left button click for reading or selection of book
        if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[0]){
  				aBook  = BookwormApp.Bookworm.libraryViewMap.get(aEventBox.get_name());
  				BookwormApp.Bookworm.readSelectedBook(aBook);
  			}
  			if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[2] ||
           BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[3]){
  				BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[3];
  				aBook  = BookwormApp.Bookworm.libraryViewMap.get(aEventBox.get_name());
  				updateLibraryViewForSelectionMode(aBook);
  			}
  			return true;
      }
		});
		//add book details to libraryView Map
		BookwormApp.Bookworm.libraryViewMap.set(aBook.getBookLocation(), aBook);
    debug("Completed updating Library View for book:"+aBook.getBookLocation());
	}

  public static void replaceCoverImageOnBook (owned BookwormApp.Book? book){
    //remove the existing overlay image
    Gtk.Overlay oldOverlayImage = (Gtk.Overlay) book.getBookWidget("BOOK_OVERLAY_IMAGE");
    oldOverlayImage.destroy();
    //create a new overlay image
    Gtk.Overlay lOverlayImage = new Gtk.Overlay();
    lOverlayImage.add(book.getBookWidget("PLACEHOLDER_COVER_IMAGE"));
    lOverlayImage.add_overlay(book.getBookWidget("SELECTION_BADGE_IMAGE"));
    lOverlayImage.add_overlay(book.getBookWidget("SELECTED_BADGE_IMAGE"));
    lOverlayImage.add_overlay(book.getBookWidget("COVER_IMAGE"));
    lOverlayImage.add_overlay(book.getBookWidget("TITLE_TEXT_LABEL"));
    book.setBookWidget("BOOK_OVERLAY_IMAGE", lOverlayImage);
    //associate the eventbox with the new overlay image
    Gtk.EventBox aEventBox = (Gtk.EventBox) book.getBookWidget("BOOK_EVENTBOX");
    aEventBox.add(lOverlayImage);
    book.setBookWidget("BOOK_EVENTBOX", aEventBox);
    //update the libraryview map with the book object
    BookwormApp.Bookworm.libraryViewMap.set(book.getBookLocation(), book);
  }

  public static void updateLibraryViewForSelectionMode(owned BookwormApp.Book? lBook){
		if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[0]){
      debug ("Updating Library View for Selection Badges BOOKWORM_UI_STATES[0]");
			//loop over HashMap of Book Objects and overlay selection image
			foreach (BookwormApp.Book book in BookwormApp.Bookworm.libraryViewMap.values){
        if(BookwormApp.AppWindow.library_grid_scroll.get_visible()){
  				Gtk.Overlay aOverlayImage = (Gtk.Overlay) book.getBookWidget("BOOK_OVERLAY_IMAGE");
          //set the order of the widgets to put the selection/selected badges at bottom
          aOverlayImage.reorder_overlay(book.getBookWidget("SELECTION_BADGE_IMAGE"), 1);
          aOverlayImage.reorder_overlay(book.getBookWidget("SELECTED_BADGE_IMAGE"), 2);
          aOverlayImage.reorder_overlay(book.getBookWidget("COVER_IMAGE"), 3);
          aOverlayImage.reorder_overlay(book.getBookWidget("TITLE_TEXT_LABEL"), 4);
        }
      }
		}
		if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[2]){
      debug ("Updating Library View for Selection Badges BOOKWORM_UI_STATES[2]");
			//loop over HashMap of Book Objects and overlay selection badge
			foreach (BookwormApp.Book book in BookwormApp.Bookworm.libraryViewMap.values){
        if(BookwormApp.AppWindow.library_grid_scroll.get_visible()){
          Gtk.Overlay aOverlayImage = (Gtk.Overlay) book.getBookWidget("BOOK_OVERLAY_IMAGE");
          //set the order of the widgets to put the selection badge on top
          aOverlayImage.reorder_overlay(book.getBookWidget("SELECTED_BADGE_IMAGE"), 1);
          aOverlayImage.reorder_overlay(book.getBookWidget("COVER_IMAGE"), 2);
          aOverlayImage.reorder_overlay(book.getBookWidget("TITLE_TEXT_LABEL"), 3);
          aOverlayImage.reorder_overlay(book.getBookWidget("SELECTION_BADGE_IMAGE"), 4);
        }
			}
		}
		if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[3]){
      debug ("Updating Library View for Selection Badges BOOKWORM_UI_STATES[3]");
      if(lBook != null){
        if(BookwormApp.AppWindow.library_grid_scroll.get_visible()){
          Gtk.Overlay aOverlayImage = (Gtk.Overlay) lBook.getBookWidget("BOOK_OVERLAY_IMAGE");
          if(!lBook.getIsBookSelected()){
            //set the order of the widgets to put the selected badge on top
            aOverlayImage.reorder_overlay(lBook.getBookWidget("SELECTION_BADGE_IMAGE"), 1);
            aOverlayImage.reorder_overlay(lBook.getBookWidget("COVER_IMAGE"), 2);
            aOverlayImage.reorder_overlay(lBook.getBookWidget("TITLE_TEXT_LABEL"), 3);
            aOverlayImage.reorder_overlay(lBook.getBookWidget("SELECTED_BADGE_IMAGE"), 4);
            lBook.setIsBookSelected(true);
          }else{
            //set the order of the widgets to put the selection badge on top
            aOverlayImage.reorder_overlay(lBook.getBookWidget("SELECTED_BADGE_IMAGE"), 1);
            aOverlayImage.reorder_overlay(lBook.getBookWidget("COVER_IMAGE"), 2);
            aOverlayImage.reorder_overlay(lBook.getBookWidget("TITLE_TEXT_LABEL"), 3);
            aOverlayImage.reorder_overlay(lBook.getBookWidget("SELECTION_BADGE_IMAGE"), 4);
            lBook.setIsBookSelected(false);
          }
        }
        //update the book into the Library view HashMap
        BookwormApp.Bookworm.libraryViewMap.set(lBook.getBookLocation(),lBook);
      }
		}
    if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[0]){
		  BookwormApp.AppWindow.library_grid.show_all();
    }
		BookwormApp.Bookworm.toggleUIState();
	}

  public static void setFilterAndSort(TreeView aTreeView, Gtk.TreeModelFilter aTreeModelFilter, SortType aSortType){
		aTreeModelFilter.set_visible_func(filterTree);
		Gtk.TreeModelSort aTreeModelSort = new TreeModelSort.with_model (aTreeModelFilter);
		aTreeView.set_model(aTreeModelSort);
		int noOfColumns = aTreeView.get_model().get_n_columns();
		for(int count=0; count<noOfColumns; count++){
			aTreeView.get_column(count).set_sort_column_id(count);
			aTreeView.get_column(count).set_sort_order(aSortType);
		}
	}

	public static bool filterTree(TreeModel model, TreeIter iter){
		bool isFilterCriteriaMatch = true;
		string modelValueString = "";
		//If there is nothing to filter or the default help text then make the data visible
		if ((BookwormApp.AppHeaderBar.headerSearchBar.get_text() == "")){
				isFilterCriteriaMatch = true;
		//extract data from the tree model and match againt the filter input
		}else{
      /* Filter on text visible on the tree view*/
			GLib.Value modelValue;
			int noOfColumns = model.get_n_columns();
			for (int count = 0; count < noOfColumns; count++){
				model.get_value (iter, count, out modelValue);
				if(modelValue.strdup_contents().strip() != null){
					//Attempt to get the value as a string - modelValueString will be empty if attempt fails
					modelValueString = modelValue.strdup_contents().strip();
					//Check the value of modelValueString and attempt to match to search string if it is not empty
					if("" != modelValueString || modelValueString != null){
						if ((modelValueString.up()).contains((BookwormApp.AppHeaderBar.headerSearchBar.get_text()).up())){
							isFilterCriteriaMatch = true;
							break;
						}else{
							isFilterCriteriaMatch =  false;
						}
					}
				}
				modelValue.unset();
			}
		}
		return isFilterCriteriaMatch;
	}

  public static bool libraryViewFilter (FlowBoxChild aEventBoxBook) {
		//execute filter only if the search text is not the default one or not blank
		if(BookwormApp.AppHeaderBar.headerSearchBar.get_text() != BookwormApp.Constants.TEXT_FOR_HEADERBAR_LIBRARY_SEARCH &&
			 BookwormApp.AppHeaderBar.headerSearchBar.get_text().strip() != ""
		){
			BookwormApp.Book aBook  = BookwormApp.Bookworm.libraryViewMap.get(((EventBox)aEventBoxBook.get_child()).get_name());
			if((aBook.getBookLocation().up()).index_of(BookwormApp.AppHeaderBar.headerSearchBar.get_text().up()) != -1){
				return true;
			}
			else if((aBook.getBookTitle().up()).index_of(BookwormApp.AppHeaderBar.headerSearchBar.get_text().up()) != -1){
				return true;
			}
			else if((aBook.getBookAuthor().up()).index_of(BookwormApp.AppHeaderBar.headerSearchBar.get_text().up()) != -1){
				return true;
			}
			else if((aBook.getBookTags().up()).index_of(BookwormApp.AppHeaderBar.headerSearchBar.get_text().up()) != -1){
				return true;
			}
			else{
				return false;
			}
		}
		return true;
	}
}
