SIZE=128x128
convert portal_black.png -filter Cubic -resize $SIZE portal_small.png
composite -compose atop "xc:#0088ff[${SIZE}!]" portal_small.png portal-blue.png
composite -compose atop "xc:orange[${SIZE}!]" portal_small.png portal-orange.png
