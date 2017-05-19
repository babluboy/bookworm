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
using Gtk;
using Gee;
public class BookwormApp.AppDialog : Gtk.Dialog {

	public AppDialog () {

	}

	public static Gtk.Popover createBookContextMenu (owned BookwormApp.Book aBook){
		debug("Context Menu Popover initiated for book:"+aBook.getBookLocation());
		Gtk.Popover bookContextPopover = new Gtk.Popover ((Gtk.EventBox) (aBook.getBookWidget("BOOK_EVENTBOX")));

		//Add the Menu title with the name of the book
		StringBuilder contextTitle = new StringBuilder();
		contextTitle.append(BookwormApp.Constants.TEXT_FOR_BOOK_CONTEXTMENU_HEADER)
							  .append(" ")
								.append(aBook.getBookTitle());
		//restrict the length of the label to 35 characters
		if(contextTitle.str.length > 35){
			contextTitle.assign(contextTitle.str.slice(0,35));
			contextTitle.append("...");
		}
		Label contextTitleLabel = new Label(contextTitle.str);

		//Add button for updating cover Image
		Gtk.Label updateCoverLabel = new Gtk.Label(BookwormApp.Constants.TEXT_FOR_BOOK_CONTEXTMENU_UPDATE_COVER);
		Gtk.Image updateImageIcon = new Gtk.Image.from_icon_name ("insert-image", Gtk.IconSize.MENU);
		Gtk.Button updateCoverImageButton = new Gtk.Button ();
		updateCoverImageButton.set_image (updateImageIcon);
		updateCoverImageButton.set_relief (ReliefStyle.NONE);
		updateCoverImageButton.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_UPDATING_COVER_IMAGE);
		Gtk.Box updateCoverImageBox = new Gtk.Box (Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_WIDGETS);
		updateCoverImageBox.pack_start(updateCoverLabel,false, true, 0);
		updateCoverImageBox.pack_start(updateCoverImageButton,false, true, 0);
		//Add action for setting cover image
		updateCoverImageButton.clicked.connect (() => {
			ArrayList<string> selectedFiles = BookwormApp.Utils.selectFileChooser(Gtk.FileChooserAction.OPEN, _("Select Image"), BookwormApp.Bookworm.window, false, "IMAGES");
			if(selectedFiles != null && selectedFiles.size > 0){
				string selectedCoverImagePath = selectedFiles.get(0);
				//copy cover image to bookworm cover image cache
	      aBook = BookwormApp.Utils.setBookCoverImage(aBook, selectedCoverImagePath);
				aBook.setWasBookOpened(true);

				//Refresh the library view to show the new cover image
				Gdk.Pixbuf aBookCover = new Gdk.Pixbuf.from_file_at_scale(aBook.getBookCoverLocation(), 150, 200, false);
				Gtk.Image aCoverImage = new Gtk.Image.from_pixbuf(aBookCover);
				aCoverImage.set_halign(Align.START);
				aCoverImage.set_valign(Align.START);
				aBook.setBookWidget("COVER_IMAGE", aCoverImage);
				BookwormApp.Library.replaceCoverImageOnBook(aBook); //book is updated into library view map in this function call
				//remove the text from the title widget
				Gtk.Label titleTextLabel = (Gtk.Label) aBook.getBookWidget("TITLE_TEXT_LABEL");
				titleTextLabel.set_text("");
				aBook.setBookWidget("TITLE_TEXT_LABEL", titleTextLabel);
				//refresh the library view
				BookwormApp.AppWindow.library_grid.show_all();
				BookwormApp.Bookworm.toggleUIState();

				debug("Updated cover to image located at path:"+selectedCoverImagePath);
			}
		});

		//Add text entry for updating book title
		Gtk.Label updateTitleLabel = new Gtk.Label(BookwormApp.Constants.TEXT_FOR_BOOK_CONTEXTMENU_UPDATE_TITLE);
		Gtk.Entry updateTitleEntry = new Gtk.Entry ();
		updateTitleEntry.set_text (aBook.getBookTitle());
		Gtk.Box updateTitleBox = new Gtk.Box (Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_WIDGETS);
		updateTitleBox.pack_start(updateTitleLabel,false, true, 0);
		updateTitleBox.pack_end(updateTitleEntry,false, true, 0);
		//Add action for setting Book Title
		updateTitleEntry.focus_out_event.connect (() => {
			if(!aBook.getIsBookCoverImagePresent() && updateTitleEntry.get_text() != null && updateTitleEntry.get_text().length > 0){
				aBook.setBookTitle(updateTitleEntry.get_text());
				aBook.setWasBookOpened(true);
				//refresh the library view
				Gtk.Label titleTextLabel = (Gtk.Label) aBook.getBookWidget("TITLE_TEXT_LABEL");
				titleTextLabel.set_text("<b>"+aBook.getBookTitle()+"</b>");
				titleTextLabel.set_xalign(0.0f);
				titleTextLabel.set_use_markup (true);
				titleTextLabel.set_line_wrap (true);
	      titleTextLabel.set_margin_start(BookwormApp.Constants.SPACING_WIDGETS);
	      titleTextLabel.set_margin_end(BookwormApp.Constants.SPACING_WIDGETS);
	      titleTextLabel.set_max_width_chars(-1);
				aBook.setBookWidget("TITLE_TEXT_LABEL", titleTextLabel);
				BookwormApp.AppWindow.library_grid.show_all();
				BookwormApp.Bookworm.toggleUIState();
			}
			return false;
		});

		//Add text entry for updating book author
		Gtk.Label updateAuthorLabel = new Gtk.Label(BookwormApp.Constants.TEXT_FOR_BOOK_CONTEXTMENU_UPDATE_AUTHOR);
		Gtk.Entry updateAuthorEntry = new Gtk.Entry ();
		updateAuthorEntry.set_text (aBook.getBookAuthor());
		Gtk.Box updateAuthorBox = new Gtk.Box (Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_WIDGETS);
		updateAuthorBox.pack_start(updateAuthorLabel,false, true, 0);
		updateAuthorBox.pack_end(updateAuthorEntry,false, true, 0);
		//Add action for setting Book Title
		updateAuthorEntry.focus_out_event.connect (() => {
			if(updateAuthorEntry.get_text() != null && updateAuthorEntry.get_text().length > 0){
				aBook.setBookAuthor(updateAuthorEntry.get_text());
				aBook.setWasBookOpened(true);
			}
			return false;
		});

		//Add text entry for tags
		Gtk.Label updateTagsLabel = new Gtk.Label(BookwormApp.Constants.TEXT_FOR_BOOK_CONTEXTMENU_UPDATE_TAGS);
		Gtk.Entry updateTagsEntry = new Gtk.Entry ();
		updateTagsEntry.set_text (aBook.getBookTags());
		Gtk.Box updateTagsBox = new Gtk.Box (Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_WIDGETS);
		updateTagsBox.pack_start(updateTagsLabel,false, true, 0);
		updateTagsBox.pack_end(updateTagsEntry,false, true, 0);
		//Add action for setting book tags
		updateTagsEntry.focus_out_event.connect (() => {
			if(updateTagsEntry.get_text() != null && updateTagsEntry.get_text().length > 0){
				aBook.setBookTags(updateTagsEntry.get_text());
				aBook.setWasBookOpened(true);
			}
			return false;
		});

		//Add/Update book ratings
		ArrayList<Gtk.Button> bookRatingList = new ArrayList<Gtk.Button> ();
		Gtk.Box ratingBox = new Gtk.Box (Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_WIDGETS);
		ratingBox.set_halign(Align.CENTER);
		//set up the widgets for the rating
		for(int i=0; i<5; i++){
			Gtk.Image rating_star_image = new Gtk.Image.from_icon_name ("help-about-symbolic", Gtk.IconSize.MENU);
			Gtk.Button rating_star_button = new Gtk.Button ();
			rating_star_button.set_image (rating_star_image);
			rating_star_button.set_relief (ReliefStyle.NONE);
			bookRatingList.add(rating_star_button);
			ratingBox.pack_start(rating_star_button,false, true, 0);
			//Add action for rating button
			rating_star_button.clicked.connect (() => {
				//set rating star clicked to active rating image
				rating_star_button.set_image(new Gtk.Image.from_icon_name ("help-about", Gtk.IconSize.MENU));
				int ratingClicked = bookRatingList.index_of(rating_star_button);
				aBook.setBookRating(ratingClicked+1);
				aBook.setWasBookOpened(true);
				debug("Book Rating Set to:"+(ratingClicked+1).to_string());
				//Adjust rating display: set all stars with lower rating to active rating image
				for(int j=0; j<ratingClicked; j++){
					((Gtk.Button)bookRatingList.get(j)).set_image(new Gtk.Image.from_icon_name ("help-about", Gtk.IconSize.MENU));
				}
				//Adjust rating display: set all stars with higher rating to in-active rating image
				for(int k=ratingClicked+1; k<5; k++){
					((Gtk.Button)bookRatingList.get(k)).set_image(new Gtk.Image.from_icon_name ("help-about-symbolic", Gtk.IconSize.MENU));
				}
			});
		}
		//If any rating was given then represent the set_name
		if(aBook.getBookRating() > 0){
			for(int l=0; l<(aBook.getBookRating()); l++){
				((Gtk.Button)bookRatingList.get(l)).set_image(new Gtk.Image.from_icon_name ("help-about", Gtk.IconSize.MENU));
			}
		}

		//Add all context widget items to a Context Box
		Gtk.Box bookContextMenuBox = new Gtk.Box(Orientation.VERTICAL, BookwormApp.Constants.SPACING_BUTTONS);
    bookContextMenuBox.set_border_width(BookwormApp.Constants.SPACING_WIDGETS);
    bookContextMenuBox.pack_start(contextTitleLabel, false, false);
    bookContextMenuBox.pack_start(new Gtk.HSeparator() , true, true, 0);
		bookContextMenuBox.pack_start(updateCoverImageBox, false, false);
		bookContextMenuBox.pack_start(updateTitleBox, false, false);
		bookContextMenuBox.pack_start(updateAuthorBox, false, false);
		bookContextMenuBox.pack_start(updateTagsBox, false, false);
		bookContextMenuBox.pack_start(new Gtk.HSeparator() , true, true, 0);
		bookContextMenuBox.pack_end(ratingBox, false, false);
		//Set Context Box to Popover
		bookContextPopover.add(bookContextMenuBox);

		//update book when popover is closed
		bookContextPopover.closed.connect(() => {
			BookwormApp.Bookworm.libraryViewMap.set(aBook.getBookLocation(), aBook);
			debug("Popover closed and Book details updated...");
		});
		debug("Context Menu Popover completed for book:"+aBook.getBookLocation());
		return bookContextPopover;
	}

	public static void createPreferencesDialog () {
		AppDialog dialog = new AppDialog ();
    dialog.title = BookwormApp.Constants.TEXT_FOR_PREFERENCES_DIALOG_TITLE;
		dialog.border_width = 5;
		dialog.set_default_size (600, 200);
		dialog.destroy.connect (Gtk.main_quit);

		Gtk.Label localStorageLabel = new Gtk.Label (BookwormApp.Constants.TEXT_FOR_PREFERENCES_LOCAL_STORAGE);
    Gtk.Switch localStorageSwitch = new Gtk.Switch ();
    //Set the switch to on if the state is in Night Mode
    if(BookwormApp.Bookworm.settings.is_local_storage_enabled){
      localStorageSwitch.set_active (true);
		}
		Gtk.Box localStorageBox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_WIDGETS);
		localStorageBox.pack_start(localStorageLabel, false, false);
		localStorageBox.pack_end(localStorageSwitch, false, false);


    Gtk.Label colourScheme = new Gtk.Label (BookwormApp.Constants.TEXT_FOR_PREFERENCES_COLOUR_SCHEME);
    Gtk.Switch nightModeSwitch = new Gtk.Switch ();
    //Set the switch to on if the state is in Night Mode
    if(BookwormApp.Constants.BOOKWORM_READING_MODE[2] == BookwormApp.Bookworm.settings.reading_profile){
      nightModeSwitch.set_active (true);
		}
		Gtk.Box prefBox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_WIDGETS);
		prefBox.pack_start(colourScheme, false, false);
		prefBox.pack_end(nightModeSwitch, false, false);

    Gtk.Box content = dialog.get_content_area () as Gtk.Box;
		content.spacing = BookwormApp.Constants.SPACING_WIDGETS;
		content.pack_start (prefBox, false, false, 0);
		content.pack_start (localStorageBox, false, false, 0);

    dialog.show_all ();

    //Set up Actions
		localStorageSwitch.notify["active"].connect (() => {
			if (localStorageSwitch.active) {
        BookwormApp.Bookworm.settings.is_local_storage_enabled = true;
			}else{
        BookwormApp.Bookworm.settings.is_local_storage_enabled = false;
			}
		});

    nightModeSwitch.notify["active"].connect (() => {
			if (nightModeSwitch.active) {
        BookwormApp.Bookworm.applyProfile(BookwormApp.Constants.BOOKWORM_READING_MODE[2]);
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
