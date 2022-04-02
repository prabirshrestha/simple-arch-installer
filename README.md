# simple-arch-installer

## Installing

1. Boot into the Arch Linux Live environment.
2. Use `iwctl station wlan0 connect "networkname"` to connect to the wifi. Internet connection is required for installation.
3. *[Optional]* If you would like to increase the terminal font size run `pacman -Sy terminus-font; setfont ter-p32n`.
4. Run the following command to start the installer.

```bash
bash <(curl -sL https://bit.ly/simple-arch-installer)
```

## Post Installation

* To increase backlight run `xbacklight -set 100`.
* To connect to internet use `nmtui`.

## License

MIT
