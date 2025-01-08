
## Install/Update Command
```sh
curl -s https://api.github.com/repos/negerleins/StudioFinder/releases/latest | grep "browser_download_url.*release.tar.gz" | cut -d : -f 2,3 | tr -d \" | wget -qi - -O - | tar -xz
```
