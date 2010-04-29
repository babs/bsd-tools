#!/bin/sh

. /etc/remote.mk
CARP=/etc/$1
if [ ! -e $CARP ]; then
    echo "File $CARP not found !"
fi


sed "s/advskew [0-9]*/advskew $ADVSKEW/" < $CARP >$CARP.tmp
if [ $? -eq 0 ]; then
    mv $CARP.tmp $CARP
    chmod o-r $CARP
else
    rm $CARP.tmp
fi

