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
using Gee;
public class BookwormApp.Library {
  public static ArrayList<BookwormApp.Book> listOfBooksInLibraryOnLoad = new ArrayList<BookwormApp.Book>();

  public static void updateLibraryView(owned BookwormApp.Book aBook){
    info("[START] [FUNCTION:updateLibraryView]");
    updateLibraryListView(aBook);
    updateLibraryGridView(aBook);
    info("[END] [FUNCTION:updateLibraryView]");
  }

  public static void updateLibraryListView(owned BookwormApp.Book aBook){
    debug("[START] [FUNCTION:updateLibraryListView] book.location="+aBook.getBookLocation());
    if(aBook.getBookTitle != null && aBook.getBookTitle().length > 1) {
        debug("Started updating Library List View for book:"+aBook.getBookLocation());
        //set the rating image
        Gdk.Pixbuf image_rating;
        string modifiedElapsedTime = "";
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
        //calculate the time elapsed from last modified DateTime
        TimeSpan timespan = (new DateTime.now_local()).difference (
                                                        new DateTime.from_unix_local(int64.parse(aBook.getBookLastModificationDate()))
                                                );
        int64 daysElapsed = timespan/(86400000000);
        if( timespan < TimeSpan.DAY){
          modifiedElapsedTime = BookwormApp.Constants.TEXT_FOR_TIME_TODAY;
        }else if(timespan < 2 * TimeSpan.DAY){
          modifiedElapsedTime = BookwormApp.Constants.TEXT_FOR_TIME_YESTERDAY;
        }else if(timespan < 30 * TimeSpan.DAY){
          modifiedElapsedTime = daysElapsed.to_string()+ " " + BookwormApp.Constants.TEXT_FOR_TIME_DAYS;
        }else{
          modifiedElapsedTime = new DateTime.from_unix_local(int64.parse(aBook.getBookLastModificationDate())).format("%d %m %Y");
        }

        BookwormApp.AppWindow.library_table_liststore.append (out BookwormApp.AppWindow.library_table_iter);
        BookwormApp.AppWindow.library_table_liststore.set (BookwormApp.AppWindow.library_table_iter,
                                0, null,
                                1, BookwormApp.Utils.parseMarkUp(aBook.getBookTitle()),
                                2, aBook.getBookAuthor(),
                                3, modifiedElapsedTime,
                                4, image_rating,
                                5, aBook.getBookTags(),
                                6, aBook.getBookRating().to_string(),
                                7, aBook.getBookLocation()
                              );
        //add book details to libraryView Map
        BookwormApp.Bookworm.libraryViewMap.set(aBook.getBookLocation(), aBook);
        BookwormApp.Bookworm.libraryTreeModelFilter = new Gtk.TreeModelFilter (BookwormApp.AppWindow.library_table_liststore, null);
        BookwormApp.Bookworm.libraryTreeModelFilter.set_visible_func(filterTree);
        Gtk.TreeModelSort aTreeModelSort = new TreeModelSort.with_model (BookwormApp.Bookworm.libraryTreeModelFilter);
        BookwormApp.AppWindow.library_table_treeview.set_model(aTreeModelSort);
        //set treeview columns for sorting
        BookwormApp.AppWindow.library_table_treeview.get_column(1).set_sort_column_id(1);
        BookwormApp.AppWindow.library_table_treeview.get_column(1).set_sort_order(SortType.DESCENDING);

        BookwormApp.AppWindow.library_table_treeview.get_column(2).set_sort_column_id(2);
        BookwormApp.AppWindow.library_table_treeview.get_column(2).set_sort_order(SortType.DESCENDING);

        BookwormApp.AppWindow.library_table_treeview.get_column(3).set_sort_column_id(3);
        BookwormApp.AppWindow.library_table_treeview.get_column(3).set_sort_order(SortType.DESCENDING);

        //6th item is the rating value corresponding to the image on the 4th item
        BookwormApp.AppWindow.library_table_treeview.get_column(4).set_sort_column_id(6);
        BookwormApp.AppWindow.library_table_treeview.get_column(4).set_sort_order(SortType.DESCENDING);

        BookwormApp.AppWindow.library_table_treeview.get_column(5).set_sort_column_id(5);
        BookwormApp.AppWindow.library_table_treeview.get_column(5).set_sort_order(SortType.DESCENDING);
    }
    debug("[END] [FUNCTION:updateLibraryListView] book.location="+aBook.getBookLocation());
  }

  public static void updateLibraryGridView(owned BookwormApp.Book aBook){
    debug("[START] [FUNCTION:updateLibraryGridView] book.location="+aBook.getBookLocation());
    if(aBook.getBookTitle != null && aBook.getBookTitle().length > 1) {
        debug("Started updating Library Grid View for book:"+aBook.getBookLocation());
        Gtk.Image aCoverImage;
        Gtk.Label titleTextLabel = new Gtk.Label("");
        Gtk.Image bookSelectionImage;
        Gtk.Image bookSelectedImage;
        string bookCoverLocation;
        Gdk.Pixbuf aBookCover;
        Gtk.Image bookPlaceholderCoverImage = null;
        try{
            Gdk.Pixbuf bookPlaceholderCoverPix = new Gdk.Pixbuf.from_file_at_scale(BookwormApp.Constants.PLACEHOLDER_COVER_IMAGE_LOCATION, 10, 200, false);
            bookPlaceholderCoverImage = new Gtk.Image.from_pixbuf(bookPlaceholderCoverPix);
        }catch(GLib.Error e) {
            warning ("Error loading the placeholder cover image from location["+BookwormApp.Constants.PLACEHOLDER_COVER_IMAGE_LOCATION+"] : "+e.message);
        }
        Gtk.ProgressBar bookProgressBar = new Gtk.ProgressBar ();

        //Add a default cover selected at random if no cover exists
        if(aBook.getBookCoverLocation() == null || aBook.getBookCoverLocation().length < 1) {
            //default Book Cover Image not set - select at random from the default covers
            bookCoverLocation = BookwormApp.Constants.DEFAULT_COVER_IMAGE_LOCATION
                                                   .replace("N", GLib.Random.int_range(1, 6).to_string());
	            aBook.setBookCoverLocation(bookCoverLocation);
            }
            try{
                aBookCover = new Gdk.Pixbuf.from_file_at_scale(aBook.getBookCoverLocation(), 150, 200, false);
                aCoverImage = new Gtk.Image.from_pixbuf(aBookCover);
            }catch(GLib.Error e){
                //Sometimes the path to the image selected by the parser is not a image
                //This catch block assigns a default cover selected at random to cover this issue
                bookCoverLocation = BookwormApp.Constants.DEFAULT_COVER_IMAGE_LOCATION
                                                    .replace("N", GLib.Random.int_range(1, 6).to_string());
	            aBook.setBookCoverLocation(bookCoverLocation);
                aCoverImage = null;
                try{
                    aBookCover = new Gdk.Pixbuf.from_file_at_scale(aBook.getBookCoverLocation(), 150, 200, false);
                    aCoverImage = new Gtk.Image.from_pixbuf(aBookCover);
                    //set cover image present flag to false - this will add title text to the default cover
                    aBook.setIsBookCoverImagePresent(false);
                    aCoverImage.set_halign(Align.CENTER);
                    aCoverImage.set_valign(Align.CENTER);
                }catch (GLib.Error e) {
                    warning("Error in loading cover image at location["+aBook.getBookCoverLocation()+"] : "+ e.message);
                }
            }
            //Add title of the book if Default Cover is being used
            if(!aBook.getIsBookCoverImagePresent()){
                titleTextLabel.set_text("<b>"+BookwormApp.Utils.breakString(aBook.getBookTitle(), 15, " ")+"</b>");
	            titleTextLabel.set_use_markup (true);
                titleTextLabel.set_line_wrap (true);
                titleTextLabel.set_justify (Justification.CENTER);
                titleTextLabel.set_margin_start(BookwormApp.Constants.SPACING_WIDGETS);
                titleTextLabel.set_margin_end(BookwormApp.Constants.SPACING_WIDGETS);

            }else{
                //remove the title label if the book has a cover image available
                titleTextLabel.set_text("");
            }
            //Add selection option badge to the book for later use
            Gdk.Pixbuf bookSelectionPix = null;
            try{
                bookSelectionPix = new Gdk.Pixbuf.from_file(BookwormApp.Constants.SELECTION_OPTION_IMAGE_LOCATION);
            }catch(GLib.Error e) {
                warning("Error in loading Book selection image from location["+
                                 BookwormApp.Constants.SELECTION_OPTION_IMAGE_LOCATION+"] : "+ e.message);
            }
            bookSelectionImage = new Gtk.Image.from_pixbuf(bookSelectionPix);
            bookSelectionImage.set_halign(Align.CENTER);
            bookSelectionImage.set_valign(Align.START);

            //Add selection checked badge to the book for later use
            Gdk.Pixbuf bookSelectedPix = null;
            try{
                bookSelectedPix = new Gdk.Pixbuf.from_file(BookwormApp.Constants.SELECTION_CHECKED_IMAGE_LOCATION);
            }catch(GLib.Error e){
                warning("Error in loading Book Selection Checked image from location["+
                                 BookwormApp.Constants.SELECTION_CHECKED_IMAGE_LOCATION+"] :"+ e.message);
            }
            bookSelectedImage = new Gtk.Image.from_pixbuf(bookSelectedPix);
            bookSelectedImage.set_halign(Align.CENTER);
            bookSelectedImage.set_valign(Align.START);

            //Set the value of the progress bar
            double progress = 0.0;
            bookProgressBar.set_halign(Align.CENTER);
            bookProgressBar.set_valign(Align.END);
            bookProgressBar.set_visible(false);
            //protect the progress bar against the show_all called on the library view
            bookProgressBar.set_no_show_all(true);

            //Create a Overlay to hold the images in the right order
            Gtk.Overlay aOverlayImage = new Gtk.Overlay();
            aOverlayImage.add(bookPlaceholderCoverImage);
            aOverlayImage.add_overlay(bookSelectionImage);
            aOverlayImage.add_overlay(bookSelectedImage);
            aOverlayImage.add_overlay(aCoverImage);
            aOverlayImage.add_overlay(titleTextLabel);
            aOverlayImage.add_overlay(bookProgressBar);//this will be invisble until mouse enters

            //Add the overlaid images to a EventBox to allow mouse click actions to be captured
            Gtk.EventBox aEventBox = new Gtk.EventBox();
            aEventBox.set_border_width (BookwormApp.Constants.SPACING_WIDGETS/2);
            aEventBox.set_name(aBook.getBookLocation());
            aEventBox.add(aOverlayImage);

            //register the book with the filter function
            var aFlowBoxChild = new Gtk.FlowBoxChild();
            aFlowBoxChild.add(aEventBox);
            libraryViewFilter(aFlowBoxChild);

            //add the book to the library view
            BookwormApp.AppWindow.library_grid.add (aFlowBoxChild);

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

            //add mouse enter listener for book object
            aEventBox.enter_notify_event.connect ((event) => {
                //calculate the progress of the book
                progress = ((double)aBook.getBookPageNumber()+1)/aBook.getBookTotalPages();
                bookProgressBar.set_fraction (progress);
                bookProgressBar.set_visible(true);
                return false;
            });

            //add mouse exit listener for book object
            aEventBox.leave_notify_event.connect ((event) => {
                //Checking for Gdk.NotifyType.INFERIOR resolves the unwanted leave event fired due to the cover being a default type image
                if(event.detail != Gdk.NotifyType.INFERIOR){
                    bookProgressBar.set_visible(false);
                }
                return false;
            });

            //add mouse click listener for book objects based on mode
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
                        BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[3])
                    {
		                BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[3];
		                aBook  = BookwormApp.Bookworm.libraryViewMap.get(aEventBox.get_name());
		                updateGridViewForSelection(aBook);
	                }
	                return true;
                }
            });
            //add book details to libraryView Map
            BookwormApp.Bookworm.libraryViewMap.set(aBook.getBookLocation(), aBook);
            if( BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[0] ||
                BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[2] ||
                BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[3])
            {
                BookwormApp.AppWindow.library_grid.show_all();
            }
            debug("Completed updating Library View for book:"+aBook.getBookLocation());
        }
        debug("[END] [FUNCTION:updateLibraryGridView] book.location="+aBook.getBookLocation());
	}

  public static void replaceCoverImageOnBook (owned BookwormApp.Book? book){
        debug("[START] [FUNCTION:replaceCoverImageOnBook]");
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
        debug("[END] [FUNCTION:replaceCoverImageOnBook]");
  }
  public static void updateListViewForSelection(owned BookwormApp.Book? lBook){
    debug("[START] [FUNCTION:updateListViewForSelection] Updating List View Selection Badges for mode:"
                +BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE);
    Gtk.TreeModelForeachFunc print_row = (model, path, iter) => {
			GLib.Value bookLocationAtRow;
			BookwormApp.AppWindow.library_table_liststore.get_value (iter, 7, out bookLocationAtRow);
            BookwormApp.Book aBook  = BookwormApp.Bookworm.libraryViewMap.get((string) bookLocationAtRow);
			if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[5]){
                BookwormApp.AppWindow.library_table_liststore.set_value (iter, 0, BookwormApp.Bookworm.image_selection_transparent_small);
                aBook.setIsBookSelected(false);
            }
            if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[6]){
                BookwormApp.AppWindow.library_table_liststore.set_value (iter, 0, BookwormApp.Bookworm.image_selection_option_small);
                aBook.setIsBookSelected(false);
            }
            if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[7] &&
              (string) bookLocationAtRow == lBook.getBookLocation())
            {
                if(!lBook.getIsBookSelected()){
                    BookwormApp.AppWindow.library_table_liststore.set_value (iter, 0, BookwormApp.Bookworm.image_selection_checked_small);
                    aBook.setIsBookSelected(true);
                }else{
                    BookwormApp.AppWindow.library_table_liststore.set_value (iter, 0, BookwormApp.Bookworm.image_selection_option_small);
                    aBook.setIsBookSelected(false);
                }
            }
            //update the book into the Library view HashMap
            BookwormApp.Bookworm.libraryViewMap.set(aBook.getBookLocation(),aBook);
			return false;
    };
	BookwormApp.AppWindow.library_table_liststore.foreach (print_row);
    debug("[END] [FUNCTION:updateListViewForSelection]");
  }

  public static void updateGridViewForSelection(owned BookwormApp.Book? lBook){
        debug("[START] [FUNCTION:updateGridViewForSelection]");
		if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[0]){
            debug ("Updating Library View for Selection Badges BOOKWORM_UI_STATES[0]");
            Gee.HashMap<string, BookwormApp.Book> temp_libraryViewMap = new Gee.HashMap<string, BookwormApp.Book> ();
			//loop over HashMap of Book Objects and overlay selection image
			foreach (BookwormApp.Book book in BookwormApp.Bookworm.libraryViewMap.values){
                if(BookwormApp.AppWindow.library_grid_scroll.get_visible()){
  				    Gtk.Overlay aOverlayImage = (Gtk.Overlay) book.getBookWidget("BOOK_OVERLAY_IMAGE");
                    //Align the selection badges to the center so that they are not visible
                    book.getBookWidget("SELECTION_BADGE_IMAGE").set_halign(Align.CENTER);
                    book.getBookWidget("SELECTED_BADGE_IMAGE").set_halign(Align.CENTER);
                    //set the order of the widgets to put the selection/selected badges at bottom
                    aOverlayImage.reorder_overlay(book.getBookWidget("SELECTION_BADGE_IMAGE"), 1);
                    aOverlayImage.reorder_overlay(book.getBookWidget("SELECTED_BADGE_IMAGE"), 2);
                    aOverlayImage.reorder_overlay(book.getBookWidget("COVER_IMAGE"), 3);
                    aOverlayImage.reorder_overlay(book.getBookWidget("TITLE_TEXT_LABEL"), 4);
                }
                temp_libraryViewMap.set(book.getBookLocation(),book);
            }
            //Iterate over all books and make the selection flag for each book as false
            //This is to cover the scenario when a book was selected and the selection mode was changed without deleting the book
            foreach (BookwormApp.Book aBook in temp_libraryViewMap.values){
                aBook.setIsBookSelected(false);
                BookwormApp.Bookworm.libraryViewMap.set(aBook.getBookLocation(),aBook);
            }
	    }
		if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[2]){
            debug ("Updating Library View for Selection Badges BOOKWORM_UI_STATES[2]");
            Gee.HashMap<string, BookwormApp.Book> temp_libraryViewMap = new Gee.HashMap<string, BookwormApp.Book> ();
            //loop over HashMap of Book Objects and overlay selection badge
	        foreach (BookwormApp.Book book in BookwormApp.Bookworm.libraryViewMap.values){
                if(BookwormApp.AppWindow.library_grid_scroll.get_visible()){
                    Gtk.Overlay aOverlayImage = (Gtk.Overlay) book.getBookWidget("BOOK_OVERLAY_IMAGE");
                    //Align the selection badges to the right to make visible but the selected badges should be centered to keep hidden
                    book.getBookWidget("SELECTION_BADGE_IMAGE").set_halign(Align.START);
                    book.getBookWidget("SELECTED_BADGE_IMAGE").set_halign(Align.CENTER);
                    //set the order of the widgets to put the selection badge on top
                    aOverlayImage.reorder_overlay(book.getBookWidget("SELECTED_BADGE_IMAGE"), 1);
                    aOverlayImage.reorder_overlay(book.getBookWidget("COVER_IMAGE"), 2);
                    aOverlayImage.reorder_overlay(book.getBookWidget("TITLE_TEXT_LABEL"), 3);
                    aOverlayImage.reorder_overlay(book.getBookWidget("SELECTION_BADGE_IMAGE"), 4);
                }
                temp_libraryViewMap.set(book.getBookLocation(),book);
	        }
            //Iterate over all books and make the selection flag for each book as false
            //This is to cover the scenario when a book was selected and the selection mode was changed without deleting the book
            foreach (BookwormApp.Book aBook in temp_libraryViewMap.values){
                aBook.setIsBookSelected(false);
                BookwormApp.Bookworm.libraryViewMap.set(aBook.getBookLocation(),aBook);
            }
	    }
		if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[3]){
            debug ("Updating Library View for Selection Badges BOOKWORM_UI_STATES[3]");
            if(lBook != null){
                if(BookwormApp.AppWindow.library_grid_scroll.get_visible()){
                    Gtk.Overlay aOverlayImage = (Gtk.Overlay) lBook.getBookWidget("BOOK_OVERLAY_IMAGE");
                    if(!lBook.getIsBookSelected()){
                        //Align the selected badges to the right to make visible but keep the selection badge centered to keep hidden
                        lBook.getBookWidget("SELECTED_BADGE_IMAGE").set_halign(Align.START);
                        lBook.getBookWidget("SELECTION_BADGE_IMAGE").set_halign(Align.CENTER);
                        //set the order of the widgets to put the selected badge on top
                        aOverlayImage.reorder_overlay(lBook.getBookWidget("SELECTION_BADGE_IMAGE"), 1);
                        aOverlayImage.reorder_overlay(lBook.getBookWidget("COVER_IMAGE"), 2);
                        aOverlayImage.reorder_overlay(lBook.getBookWidget("TITLE_TEXT_LABEL"), 3);
                        aOverlayImage.reorder_overlay(lBook.getBookWidget("SELECTED_BADGE_IMAGE"), 4);
                        lBook.setIsBookSelected(true);
                    }else{
                        //set the order of the widgets to put the selection badge on top
                        //Align the selection badges to the right to make visible but keep the selected badges centered to keep hidden
                        lBook.getBookWidget("SELECTION_BADGE_IMAGE").set_halign(Align.START);
                        lBook.getBookWidget("SELECTED_BADGE_IMAGE").set_halign(Align.CENTER);
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
        debug("[END] [FUNCTION:updateGridViewForSelection]");
    }

	public static bool filterTree(TreeModel model, TreeIter iter){
        debug("[START] [FUNCTION:filterTree]");
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
        debug("[END] [FUNCTION:filterTree]");
		return isFilterCriteriaMatch;
	}

  public static bool libraryViewFilter (FlowBoxChild aFlowBoxWidget) {
        debug("[START] [FUNCTION:libraryViewFilter]");
		//execute filter only if the search text is not the default one or not blank
		if(BookwormApp.AppHeaderBar.headerSearchBar.get_text() != BookwormApp.Constants.TEXT_FOR_HEADERBAR_LIBRARY_SEARCH &&
			 BookwormApp.AppHeaderBar.headerSearchBar.get_text().strip() != ""
		){
            var aEventBoxBook = aFlowBoxWidget.get_child();
            BookwormApp.Book aBook  = BookwormApp.Bookworm.libraryViewMap.get(aEventBoxBook.get_name());
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
      else if((aBook.getAnnotationTags().up()).index_of(BookwormApp.AppHeaderBar.headerSearchBar.get_text().up()) != -1){
				return true;
			}else{
				return false;
			}
		}
        debug("[END] [FUNCTION:libraryViewFilter]");
		return true;
	}

  public static void removeSelectedBooksFromLibrary(){
        debug("[START] [FUNCTION:removeSelectedBooksFromLibrary]");
		ArrayList<string> listOfBooksToBeRemoved = new ArrayList<string> ();
		//loop through the Library View Hashmap and remove the selected books from the Library View Model
		foreach (BookwormApp.Book book in BookwormApp.Bookworm.libraryViewMap.values){
			//check if the book selection flag to true and add it to removal list
			if(book.getIsBookSelected()){
				//hold the books to be deleted in a list
				listOfBooksToBeRemoved.add(book.getBookLocation());
				Gtk.EventBox lEventBox = (Gtk.EventBox) book.getBookWidget("BOOK_EVENTBOX");
				//destroy the EventBox parent widget - this removes the book from the library grid
				lEventBox.get_parent().destroy();
				//destroy the EventBox widget
				lEventBox.destroy();
				//remove the cover image if it exists (ignore default covers)
				if(book.getBookCoverLocation().index_of(
                    BookwormApp.Constants.DEFAULT_COVER_IMAGE_LOCATION.replace("-cover-N.png","")) == -1)
                {
					BookwormApp.Utils.execute_sync_command("rm \""+book.getBookCoverLocation()+"\"");
				}
                //update the onloadBookList - this is to enable re-adding the book within the same session
                BookwormApp.Bookworm.pathsOfBooksInLibraryOnLoadStr.
                                            assign(BookwormApp.Bookworm.pathsOfBooksInLibraryOnLoadStr.str.replace(book.getBookLocation(), ""));
                BookwormApp.Library.listOfBooksInLibraryOnLoad.remove(book);
		    }
		}

		if(listOfBooksToBeRemoved.size > 0){
			//loop through the rows in the treeview and remove the selected books
			ArrayList<Gtk.TreeIter ?> listOfItersToBeRemoved = new ArrayList<Gtk.TreeIter ?> ();
			Gtk.TreeModelForeachFunc print_row = (model, path, iter) => {
				GLib.Value bookLocationAtRow;
				BookwormApp.AppWindow.library_table_liststore.get_value (iter, 7, out bookLocationAtRow);
				if((string) bookLocationAtRow in listOfBooksToBeRemoved){
					listOfItersToBeRemoved.add(iter);
				}
				return false;
			};
			BookwormApp.AppWindow.library_table_liststore.foreach (print_row);
			foreach(Gtk.TreeIter iterToBeRemoved in listOfItersToBeRemoved){
                //remove item for list store - vala_36 compatibility wrapper
                #if VALA_0_36
	                BookwormApp.AppWindow.library_table_liststore.remove (ref iterToBeRemoved);
                #else
	                BookwormApp.AppWindow.library_table_liststore.remove (iterToBeRemoved);
                #endif
			}
		}

		//loop through the removed books and remove them from the Library View Hashmap, local cache and Database
		foreach (string bookLocation in listOfBooksToBeRemoved) {
			BookwormApp.DB.removeBookFromDB(BookwormApp.Bookworm.libraryViewMap.get(bookLocation));
			BookwormApp.Bookworm.libraryViewMap.unset(bookLocation);
		}
		//Set to normal grid view if the current view is in any of the Grid View State
		if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[0] ||
			 BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[2] ||
			 BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[3])
		{
			BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[0];
			BookwormApp.Library.updateGridViewForSelection(null);
		}
		//Set to normal list view if the current view is in any of the List View State
		if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[5] ||
			 BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[6] ||
			 BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[7])
		{
			BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[5];
			BookwormApp.Library.updateListViewForSelection(null);
		}
		BookwormApp.Bookworm.toggleUIState();
        debug("[END] [FUNCTION:removeSelectedBooksFromLibrary]");
	}

  public static async void updateLibraryViewFromDB(){
        debug("[START] [FUNCTION:updateLibraryViewFromDB]");
        foreach (BookwormApp.Book book in listOfBooksInLibraryOnLoad){
	        //add the book to the UI - both grid and list view
	        BookwormApp.Library.updateLibraryView(book);
	        Idle.add (updateLibraryViewFromDB.callback);
	        yield;
        }
        debug("[END] [FUNCTION:updateLibraryViewFromDB]");
	}

  public static async void addBooksToLibrary (){
        debug("[START] [FUNCTION:addBooksToLibrary]");
        debug("books to be added="+BookwormApp.Bookworm.pathsOfBooksToBeAdded.length.to_string());        
        double progress = 0d;
		//loop through the command line and add books to library
		foreach(string pathToSelectedBook in BookwormApp.Bookworm.pathsOfBooksToBeAdded){
            //Set async callback only if multiple books are being added
            //If only one book is being added, complete parsing and adding the book,
            //so that it will be added to the BookwormApp.Bookworm.libraryViewMap and opened on the
            //BookwormApp.contentHandler.performStartUpActions method
            if(BookwormApp.Bookworm.pathsOfBooksToBeAdded.length > 2){
                Idle.add (addBooksToLibrary.callback);
            }
            BookwormApp.Bookworm.noOfBooksAddedFromCommand++;
            if("bookworm" != pathToSelectedBook.strip()) {//ignore the first command which is the application name
                //set progress for the UI Book addition progress bar
                progress = (((double)(BookwormApp.Bookworm.noOfBooksAddedFromCommand))/
                                    ((double)(BookwormApp.Bookworm.pathsOfBooksToBeAdded.length)));
                BookwormApp.AppWindow.bookAdditionBar.set_text (_("Adding ") +
                                    ((int)(progress*100)).to_string() +
                                    "% : " +
                                    File.new_for_path(pathToSelectedBook).get_basename()
                                    );
                BookwormApp.AppWindow.bookAdditionBar.set_fraction (progress);
            }
            //Return control back for any further actions only if multiple books are being added
            //If only one book is being added, complete parsing and adding the book,
            //so that it will be added to the BookwormApp.Bookworm.libraryViewMap and opened on the 
            //BookwormApp.contentHandler.performStartUpActions method
            if(BookwormApp.Bookworm.pathsOfBooksToBeAdded.length > 2){
                yield;
            }
			if("bookworm" != pathToSelectedBook.strip()){  //ignore the first command which is the application name
                //check if book already exists in the library
                if(BookwormApp.Bookworm.pathsOfBooksInLibraryOnLoadStr.str.index_of(pathToSelectedBook.strip()) != -1){
                    debug("Book already exists in library..."+BookwormApp.Bookworm.pathsOfBooksInLibraryOnLoadStr.str);
    		        //Enable the flag which will scroll the page to the last read position
                    BookwormApp.Bookworm.isPageScrollRequired = true;
                    //set the name of the book being currently read
  				    BookwormApp.Bookworm.locationOfEBookCurrentlyRead = pathToSelectedBook.strip();
                }else{
                    //book does not exist in library - create a new instance for the book
  				    BookwormApp.Book aBookBeingAdded = new BookwormApp.Book();
  				    aBookBeingAdded.setBookLocation(pathToSelectedBook.strip());
  				    //the book will be updated to the libraryViewMap within the addBookToLibrary function
                    //however the libraryViewMap will only be fully populated when all books are added to it
  				    addBookToLibrary(aBookBeingAdded);
                    //update the onloadBookList - this is to prevent re-adding the book within the same session
                    BookwormApp.Bookworm.pathsOfBooksInLibraryOnLoadStr.append(aBookBeingAdded.getBookLocation());
                    BookwormApp.Library.listOfBooksInLibraryOnLoad.add(aBookBeingAdded);
                }
			}
		}
		//Hide the progress bar on completion of adding books
        BookwormApp.AppWindow.bookAdditionBar.hide();
        BookwormApp.Bookworm.isBookBeingAddedToLibrary = false;
        BookwormApp.Bookworm.noOfBooksAddedFromCommand = 0;
        debug("[END] [FUNCTION:addBooksToLibrary]");
	}

	public static void addBookToLibrary(owned BookwormApp.Book aBook){
        debug("[START] [FUNCTION:addBookToLibrary] book.location="+aBook.getBookLocation());
		//check if the selected eBook exists
		string eBookLocation = aBook.getBookLocation();
		File eBookFile = File.new_for_path (eBookLocation);
		if(eBookFile.query_exists() && eBookFile.query_file_type(0) != FileType.DIRECTORY){
			//insert book details to database and fetch the ID
			int bookID = BookwormApp.DB.addBookToDataBase(aBook);
			aBook.setBookId(bookID);
			/*Other than location, nothing is inserted into the DB for the book at this time.
			Mark book as opened in the session so that details for book are updated
			into DB when the application is closed - eBook parsing happens after the initial insert
			*/
			aBook.setBookLastModificationDate((new DateTime.now_utc().to_unix()).to_string());
			aBook.setWasBookOpened(true);
			//parse eBook to populate cache and book meta data
			aBook = BookwormApp.Bookworm.genericParser(aBook);
			if(!aBook.getIsBookParsed()){
				BookwormApp.DB.removeBookFromDB(aBook);
				BookwormApp.AppWindow.showInfoBar(aBook, MessageType.WARNING);
			}else{
				//add eBook cover image to library view
				BookwormApp.Library.updateLibraryView(aBook);
				//Set to normal grid view if the current view is in any of the Grid View State
				if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[0] ||
					 BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[2] ||
					 BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[3])
				{
					BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[0];
					BookwormApp.Library.updateGridViewForSelection(null);
				}
				//Set to normal list view if the current view is in any of the List View State
				if(BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[5] ||
					 BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[6] ||
					 BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE == BookwormApp.Constants.BOOKWORM_UI_STATES[7])
				{
					BookwormApp.Bookworm.BOOKWORM_CURRENT_STATE = BookwormApp.Constants.BOOKWORM_UI_STATES[5];
					BookwormApp.Library.updateListViewForSelection(null);
				}
				BookwormApp.Bookworm.toggleUIState();
				//set the name of the book being currently read
				BookwormApp.Bookworm.locationOfEBookCurrentlyRead = eBookLocation;
				debug ("Completed adding book to ebook library. Number of books in library:"+BookwormApp.Bookworm.libraryViewMap.size.to_string());
			}
		}else{
			debug("No ebook found for adding to library");
		}
        debug("[END] [FUNCTION:addBookToLibrary] book.location="+aBook.getBookLocation());
	}
}
