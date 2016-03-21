# Utility functions in bash for ATLO/CELL Containers

# Preamble
[ -z "$CELL_ETCD_PREFIX" ] && CELL_ETCD_PREFIX="/"  # Default prefix is root
[ -z "$CELL_ETCD_NODE" ] && CELL_ETCD_NODE="http://${HOST_IP}:2379" # IANA PORT use host IP as cell node with IANA PORT
[ "${CELL_ETCD_PREFIX: -1}" != "/" ] && CELL_ETCD_PREFIX="${CELL_ETCD_PREFIX}/" # ADD / to prefix if not set
[ -z "$CELL_SECRET_FILE" ] && CELL_SECRET_FILE="/opt/keyring/.secret.gpg"  # set secret file
[ -z "$CELL_PUBLIC_FILE" ] && CELL_PUBLIC_FILE="/opt/keyring/.public.gpg"  # set public file if needed

# ETCDCTL + crypt functions
# Check if entry is present
function etcdctl_present_abs {
	etcdctl -C $CELL_ETCD_NODE ls $1 &> /dev/null
	if [ $? -eq 0 ] ; then
		return 0
	else
		return 1
	fi
}
function etcdctl_present {
	etcdctl_present_abs ${CELL_ETCD_PREFIX}$1
	return $?
}

# Get value of key with defautl
function etcdctl_get_abs {
	local v=$(etcdctl -C $CELL_ETCD_NODE get $1)
	if [ $? -eq 0 ] ; then
		echo "$v"
	else
		echo "$2"
	fi
	return
}
function etcdctl_get {
	etcdctl_get_abs ${CELL_ETCD_PREFIX}$1 '$2'
	return
}

function etcdctl_set_abs {
	etcdctl -C $CELL_ETCD_NODE set "$1" "$2" &> /dev/null
	return $?
}

function etcdctl_set {
	etcdctl_set_abs "${CELL_ETCD_PREFIX}$1" "$2"
	return $?
}

function crypt_get_abs {
	local v=$(crypt get -endpoint="$CELL_ETCD_NODE" -secret-keyring="${CELL_SECRET_FILE}" $1)
	if [ $? -eq 0 ] ; then
		echo "$v"
	else
		echo "$2"
	fi
	return 0
}

function crypt_get {
	crypt_get_abs ${CELL_ETCD_PREFIX}$1 '$2'
	return
}

# Simple locker service in ETCD
# @params $1 -> loker name , $2-> wait time
function set_locker {
	local wait_t=$2
	if [ $wait_t -lt 4 ]; then $wait_t=4 fi
	local n= expr $wait_t / 4
	for i in {1..$n}
	do
		etcdctl -C $CELL_ETCD_NODE set --swap-with-value 'locked' ${CELL_ETCD_PREFIX}$1 'free' &> /dev/null
		if [ $? -eq 0 ]; then
			return 0
		else
			sleep 4
		fi
	done
	return 1;
}
# Release locker
# $1 -> locker name
function release_locker {
	etcdctl -C $CELL_ETCD_NODE set --swap-with-value 'free' ${CELL_ETCD_PREFIX}$1 'locked' &> /dev/null
	return $?
}
