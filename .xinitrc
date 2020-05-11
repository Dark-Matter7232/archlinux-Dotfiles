source /etc/X11/xinit/xinitrc.d/50-systemd-user.sh
exec /usr/lib/xfce-polkit/xfce-polkit
setxkbmap -layout us -variant intl
xbindkeys
numlockx &
exec i3
feh --bg-max --randomize ~/.wallpapers/* &
