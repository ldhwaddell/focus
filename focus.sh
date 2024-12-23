#!/bin/bash

# Hosts file path:
HOSTS_FILE="/etc/hosts"

# Fn to list the current file
list() {
	# If hosts exists and is readable
	if [[ -r "$HOSTS_FILE" ]]; then
		# use diff output based on the size of hosts
		if [[ $(wc -l <"$HOSTS_FILE") -gt 20 ]]; then
			less "$HOSTS_FILE"
		else
			cat "$HOSTS_FILE"
		fi
	else
		echo "Error: Cannot read $HOSTS_FILE."
		exit 1
	fi
}

# Fn to add a url to hosts
add() {
	local url=$1

	if [[ -z "$url" ]]; then
		echo "Useage: focus add <url>"
		exit 1
	fi

	# Check if url already in hosts
	if rg -qi "^[[:space:]]*127\.0\.0\.1[[:space:]]+$url" "$HOSTS_FILE"; then
		echo "The URL '$url' is already in $HOSTS_FILE"
	else
		local ip_addr="127.0.0.1"
		echo "$ip_addr $url" | sudo tee -a $HOSTS_FILE >/dev/null
		echo "Added $url to $HOSTS_FILE"
	fi

}

# Fn to remove a url from hosts
remove() {
	local url=$1

	if [[ -z "$url" ]]; then
		echo "Useage: focus remove <url>"
		exit 1
	fi

	# Check if url already in hosts
	if rg -qi "^[[:space:]]*127\.0\.0\.1[[:space:]]+$url" "$HOSTS_FILE"; then
		# Remove with sed, creating backup.
		sudo sed -E -i.bak "/^[[:space:]]*127\.0\.0\.1[[:space:]]+$url/d" "$HOSTS_FILE"

		echo "Removed $url from $HOSTS_FILE. Backup saved as $HOSTS_FILE.bak"
	else
		echo "'$url' was not found in $HOSTS_FILE"
	fi
}

# Sync hosts file by flushing dns.
sync() {
	echo "Flushing DNS cache..."

	if [[ "$(uname)" == "Darwin" ]]; then
		sudo dscacheutil -flushcache
		sudo killall -HUP mDNSResponder
		echo "DNS cache flushed on macOS."

	elif [[ "$(uname)" == "Linux" ]]; then
		if command -v systemd-resolve &>/dev/null; then
			sudo systemd-resolve --flush-caches
			echo "DNS cache flushed on Linux using systemd-resolve."
		elif command -v resolvectl &>/dev/null; then
			sudo resolvectl flush-caches
			echo "DNS cache flushed on Linux using resolvectl."
		else
			echo "Error: Unable to flush DNS cache on Linux. Command not found."
		fi
	else
		echo "Error: DNS cache flushing is not supported on current OS."
		exit 1
	fi

}

case "$1" in
list)
	list
	;;
add)
	add "$2"
	;;
remove)
	remove "$2"
	;;
sync)
	sync
	;;
*)
	echo "Usage: focus {list|sync|add <url>|remove <url>}"
	exit 1
	;;
esac
