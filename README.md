# A tool for backing up Postgres to Tarsnap

This contains Tarsnap and a script that greatly simplifies the process of backing up a Postgres database that is running in a Docker container. It assumes that the database container is linked as `postgres`, and that the database name, schema, user and password of the database have been configured via the same environment variables used by the [official Postgres image](https://hub.docker.com/_/postgres/).

This tool leverages Tarsnap's ability to directly consume a tar file from standard input, and restore it to standard output, in combination with `pg_dump` and `pg_restore` supporting uncompressed tar files via stdio. Compression by `pg_dump` is disabled in order to allow Tarsnap's content-aware deduplication and compression to work effectively.

## Usage

### Create the data container

The volume held by this container will store the Tarsnap key and persistent cache.

    sudo docker create \
        --name postgres-tarsnap-data \
        --volume /tarsnap \
        tianon/true

### Install the Tarsnap key

Generate your tarsnap key using `tarsnap-keygen`, then run this container with a tty and the `install-key` command and paste the key into the container's input. Afer closing the input with Ctrl-D, the key will be installed in the data container, and a Tarsnap fsck will run to (re-)populate the cache.

    sudo docker run -it --rm \
        --volumes-from postgres-tarsnap-data \
        koinu/postgres-tarsnap install-key

### Backing Up

Backup names are always generated based on the database name and time (UTC).

To create a backup, run this container with your database linked as `postgres`, with `backup` as the command (the default):

    sudo docker run --rm \
        --volumes-from postgres-tarsnap-data \
        --link your-postgres-container-name:postgres \
        koinu/postgres-tarsnap

### Listing Backups

To list available timestamps to restore from, run this container with your database linked as `postgres` and `list-backups` as the command:

    sudo docker run --rm \
        --volumes-from postgres-tarsnap-data \
        --link your-postgres-container-name:postgres \
        koinu/postgres-tarsnap list-backups

### Restoring from Backup

Note: The restore process implemented is destructive (`pg_restore` is invoked with `--clean`).

You can specify the name (formatted time) of a backup to restore as the second argument. If you omit this, the most recent backup (by name) will be restored.

    sudo docker run --rm \
        --volumes-from postgres-tarsnap-data \
        --link your-postgres-container-name:postgres \
        koinu/postgres-tarsnap restore

## Other Commands

*   `fsck`: (Re-)populate Tarsnap's cache. You need to run this after interacting with the backups from a Tarsnap client using a different cache directory.
*   `nuke`: Delete all backups. You need to run the container with a tty to do this, as Tarsnap will ask you to retype a phrase to confirm you *really* want to do this.

## Note

I strongly recommend that you do not install a full-rights key anywhere on your servers. Instead, run `tarsnap-keygen` somewhere secure and then use `tarsnap-keymgmt` to create a key with only read and write access (no delete). Having only the restricted key on your server will prevent an attacker who is able to compromise your server (but not your administrative host) from destroying your backups.
