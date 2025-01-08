![Showcase1](https://github.com/negerleins/StudioFinder/blob/main/img1.png?raw=true)
![Showcase2](https://github.com/negerleins/StudioFinder/blob/main/img2.png?raw=true)


## Install/Update Command
```sh
curl -s https://api.github.com/repos/negerleins/StudioFinder/releases/latest | grep "browser_download_url.*release.tar.gz" | cut -d : -f 2,3 | tr -d \" | wget -qi - -O - | tar -xz -C ~/ && sleep 1 && bash ~/StudioFinder/install.sh
```
