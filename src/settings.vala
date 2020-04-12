/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and is used for persisting
* the state of the window and associated user prefferences
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

public class BookwormApp.Settings : Granite.Services.Settings {
    private static Settings? instance = null;

    public int window_width { get; set; }
    public int window_height { get; set; }
    public int pos_x { get; set; }
    public int pos_y { get; set; }
    public bool window_is_maximized { get; set; }
    public double zoom_level { get; set; }
    public string reading_profile { get; set; }
    public bool is_dark_theme_enabled { get; set; }
    public bool is_local_storage_enabled { get; set; }
    public bool is_show_library_on_start { get; set; }
    public string reading_width { get; set; }
    public string reading_line_height { get; set; }
    public string text_alignment { get; set; }
    public string library_view_mode { get; set; }
    public string reading_font_name { get; set; }
    public string reading_font_name_family { get; set; }
    public int reading_font_size { get; set; }
    public string list_of_profile_colors { get; set; }
    public string list_of_scan_dirs { get; set; }
    public string book_being_read { get; set; }
    public bool is_two_page_enabled { get; set; }
    public string current_info_tab { get; set; }
    public bool is_fullscreen { get; set; }
    public int library_page_items { get; set; }
    public SettingsOfShortcuts shortcuts { get; set; }

    public static Settings get_instance () {
        if (instance == null) {
            instance = new Settings ();
        }
        return instance;
    }

    private Settings () {
        base (BookwormApp.Constants.bookworm_id);
        this.shortcuts = new SettingsOfShortcuts ();
    }
}

public class BookwormApp.SettingsOfShortcuts : Granite.Services.Settings {

    public SettingsOfShortcuts () {
        base.with_path (BookwormApp.Constants.bookworm_shortcuts_id, "/com/github/babluboy/bookworm/shortcuts/");
    }

    public string[] toggle_library_view { get; set; }
    public string[] move_library_page_backward { get; set; }
    public string[] move_library_page_forward { get; set; }
    public string[] return_to_library_view { get; set; }
    public string[] move_page_backward { get; set; }
    public string[] move_page_forward { get; set; }
    public string[] increase_zoom_level { get; set; }
    public string[] decrease_zoom_level { get; set; }
    public string[] toggle_bookmark { get; set; }
    public string[] unfullscreen { get; set; }
    public string[] toggle_fullscreen { get; set; }
    public string[] close_bookworm_completely { get; set; }
    public string[] focus_on_header_search_bar { get; set; }

}
