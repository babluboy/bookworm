# bookworm
A simple, focused eBook reader

Author: Siddhartha Das

Read the books you love without having to worry about the different format complexities like epub, pdf, mobi, cbr, etc. This version supports EPUB, PDF and Comics (CBR and CBZ) formats with support for more formats to follow soon.

## How to install bookworm:

```shell
sudo add-apt-repository ppa:bookworm-team/bookworm
sudo apt-get update
sudo apt-get install bookworm
```

## How to build bookworm:

```shell
sudo apt-get build-dep granite-demo 
sudo apt-get install libgranite-dev
sudo apt-get install valac
sudo apt-get install libwebkit2gtk-4.0-37 libwebkit2gtk-4.0-dev
sudo apt-get install sqlite3 libsqlite3-dev
sudo apt-get install poppler-utils libpoppler-glib-dev

git clone https://github.com/babluboy/bookworm.git
cd bookworm
mkdir build && cd build 
cmake -DCMAKE_INSTALL_PREFIX=/usr ../
make
```
## Screenshots

![screenshot](https://raw.githubusercontent.com/babluboy/bookworm/master/screenshots/BookwormLibraryView.jpeg)
![screenshot](https://raw.githubusercontent.com/babluboy/bookworm/master/screenshots/BookwormReadingView.jpeg)

Bookworm in Night View Mode

![screenshot](https://raw.githubusercontent.com/babluboy/bookworm/master/screenshots/BookwormLibraryViewNightView.jpeg)
![screenshot](https://raw.githubusercontent.com/babluboy/bookworm/master/screenshots/BookwormReadingViewNightView.jpeg)

Selection for deleting books from the library

![screenshot](https://raw.githubusercontent.com/babluboy/bookworm/master/screenshots/BookwormLibraryViewSelectionMode.jpeg)
