
![StudioFinder Logo](https://example.com/path/to/logo.png)
![Screenshot](https://example.com/path/to/screenshot.png)

## Install/Update Command
```sh
curl -s https://api.github.com/repos/negerleins/StudioFinder/releases/latest | grep "browser_download_url.*release.tar.gz" | cut -d : -f 2,3 | tr -d \" | wget -qi - -O - | tar -xz -C ~/ && sleep 1 && bash ~/StudioFinder/install.sh
```
