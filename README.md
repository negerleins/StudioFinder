<div style="display: flex; align-items: center;">
    <img src="https://github.com/negerleins/StudioFinder/blob/main/bin/logo.png?raw=true" alt="Logo" style="width: 100px; margin-right: 20px;">
    <h1>StudioFinder - @negerleins</h1>
</div>


<img src="https://github.com/negerleins/StudioFinder/blob/main/img1.png?raw=true" alt="Showcase1" style="width: 55%;">
<img src="https://github.com/negerleins/StudioFinder/blob/main/img2.png?raw=true" alt="Showcase2" style="width: 55%;">

## Install/Update Command
```sh
curl -s https://api.github.com/repos/negerleins/StudioFinder/releases/latest | grep "browser_download_url.*release.tar.gz" | cut -d : -f 2,3 | tr -d \" | wget -qi - -O - | tar -xz -C ~/ && sleep 1 && bash ~/StudioFinder/install.sh
```
