#!/system/bin/sh
ART="$MODPATH/mahiru.art"

if [ -f "$ART" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        ui_print "$line"
    done < "$ART"
else
    ui_print "MahiruSleep XOS16 G200"
fi

ui_print " "
ui_print "Infinix X6885 | Helio G200 | XOS 16"
