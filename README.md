# syno-rsync-backup #

Script to make a pull backup of a remote device via ssh and make sure it gets the right permissions/acls on the synology. the additional move/copy commands are needed, because otherwise the files won't get synology acls and are not correctly writeable.