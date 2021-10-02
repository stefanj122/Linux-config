#!/bin/sh

 urlpath=$( \
curl "https://www.bing.com/HPImageArchive.aspx?format=rss&idx=0&n=1&mkt=en-US" \
| xmllint --xpath "/rss/channel/item/link/text()" - \
| sed 's/1366x768/1920x1080/g' \
)
curl "https://www.bing.com$urlpath" \
| feh --bg-fill -

PID=$(pgrep -fc bingwall)

if [[ $PID -ge 2 ]]
then
	echo "Bing wallpapers is running."
else
	while :
	do

		urlpath=$( \
		curl "https://www.bing.com/HPImageArchive.aspx?format=rss&idx=0&n=1&mkt=en-US" \
		| xmllint --xpath "/rss/channel/item/link/text()" - \
		| sed 's/1366x768/1920x1080/g' \
		)
		curl "https://www.bing.com$urlpath" \
		| feh --bg-fill -
		sleep 3600
	done
fi
