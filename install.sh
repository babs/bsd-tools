#!/bin/sh

check_line_in_file () {
    FILE=$1
    shift
    KW=$1
    shift
    MSG="$@"
    if ! grep -qE "^$KW=" $FILE; then
	  echo "$MSG"
	  return 1
    fi
}

display_warning () {
    cat <<EOF

/!\ WARNING /!\\
The bsd-tools will be inoperant until $@

EOF

}

for f in apply_sysctl mail_diff Makefile update_carp.sh; do
    # -e checks file AND symlink pointing to a file. if the symling point to an invalid path, -e return false
    # Or I'd like to know if it's a symlink even if it's broken
    if [ -e /etc/$f -o -h /etc/$f ]; then
	  if [ ! -h /etc/$f ]; then
		echo "Warning, /etc/$f already exists and is NOT a symlink."
	  else
		if [ "$PWD/$f" != $(readlink /etc/$f) ]; then
		    echo "Warning, the symlink doesn't point to $PWD/$f !!"
		fi
	  fi
    else
	  ln -s $PWD/$f /etc/$f
    fi
done

if [ ! -e /etc/remote.mk ]; then
display_warning you setup a /etc/remote.mk like this:
cat sample.remote.mk
else
    echo "[+] Checking /etc/remote.mk config..."
    cat sample.remote.mk | while read L; do
	  KW=$( echo $L | cut -d= -f1)
	  check_line_in_file /etc/remote.mk $KW " -> MISSING: $L"
	  if [ $? -eq 1 ]; then
		touch /tmp/bsd-tools-bad-conf
	  fi
    done
    echo "[+] Check done"

    if [ -e /tmp/bsd-tools-bad-conf ]; then
	  display_warning "you resolv those errors"
	  rm /tmp/bsd-tools-bad-conf
    fi
fi