# Bookworm [![Translation status](https://hosted.weblate.org/widgets/bookworm/-/svg-badge.svg)](https://hosted.weblate.org/engage/bookworm/?utm_source=widget) [![Build Status](https://travis-ci.org/babluboy/bookworm.svg?branch=master)](https://travis-ci.org/babluboy/bookworm) [![Snap Status](https://build.snapcraft.io/badge/babluboy/bookworm.svg)](https://build.snapcraft.io/user/babluboy/bookworm) [![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=FZP8GK839VGQC)
A simple, focused eBook reader

Author: Siddhartha Das

Read the books you love without having to worry about the different format complexities like epub, pdf, mobi, cbr, etc. This version supports EPUB, PDF and Comics (CBR and CBZ) formats with support for more formats to follow soon.

Check the Bookworm website for details on features, shortcuts, installation guides for supported distro. : https://babluboy.github.io/bookworm/


## How to build bookworm:

### On debian

```shell
sudo apt-get build-dep granite-demo
sudo apt-get install granite-demo
sudo apt-get install libgranite-dev
sudo apt-get install valac
sudo apt-get install libwebkit2gtk-4.0-37 libwebkit2gtk-4.0-dev
sudo apt-get install libsqlite3-dev
sudo apt-get install poppler-utils libpoppler-glib-dev html2text curl
```
### On fedora

```shell
sudo dnf install cmake gcc-c++ vala
sudo dnf install gtk3-devel libgee-devel granite-devel
sudo dnf install webkitgtk4-devel sqlite-devel poppler-glib-devel html2text
```

### Build and install bookworm

```shell
git clone https://github.com/babluboy/bookworm.git
cd bookworm
mkdir build && cd build 
cmake -DCMAKE_INSTALL_PREFIX=/usr ../
make
sudo make install
```
## Screenshots

![screenshot](https://raw.githubusercontent.com/babluboy/bookworm/gh-pages/images/BookwormLibraryView.png)
![screenshot](https://raw.githubusercontent.com/babluboy/bookworm/gh-pages/images/BookwormReadingView.png)

Two Page View
![screenshot](https://raw.githubusercontent.com/babluboy/bookworm/gh-pages/images/TwoPageView.png)

Bookworm Dark Mode
![screenshot](https://raw.githubusercontent.com/babluboy/bookworm/gh-pages/images/DarkModeLibraryView.png)
![screenshot](https://raw.githubusercontent.com/babluboy/bookworm/gh-pages/images/DarkModeReadingView.png)

Library List View
![screenshot](https://raw.githubusercontent.com/babluboy/bookworm/gh-pages/images/LibraryListView.png)

Bookworm Preferences
![screenshot](https://raw.githubusercontent.com/babluboy/bookworm/gh-pages/images/PreferencesDialog.png)

