cd /home/sid/Documents/Projects/bookworm/dev/
rm -Rf ./build/*
cd ./build/
cmake -DCMAKE_INSTALL_PREFIX=/usr ../
make
sudo make install
