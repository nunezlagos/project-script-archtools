if pgrep -xl "code-oss" > /dev/null; then
    bspc desktop -f ^6
else
    bspc desktop -f ^6 && code
fi
