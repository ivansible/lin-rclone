# ivansible.lin_rclone

[![Github Test Status](https://github.com/ivansible/lin-rclone/workflows/test/badge.svg?branch=master)](https://github.com/ivansible/lin-rclone/actions)
[![Ansible Galaxy](https://img.shields.io/badge/galaxy-ivansible.lin__rclone-68a.svg?style=flat)](https://galaxy.ansible.com/ivansible/lin_rclone/)

This role installs rclone on linux, creates fuse wrapper for mount,
configures remotes, adds fstab entries or systemd mount units
and triggers systemd automounter.
It also creates the `rclone` group for read-only access to rclone
configuration and non-root mounts.


## Requirements

None


## Variables

Available variables are listed below, along with default values.

    lin_rclone_version: latest
    lin_rclone_repo_owner: rclone
    lin_rclone_upgrade: false
Set the rclone download location, allow to upgrade already installed binary.

    lin_rclone_binary: /usr/bin/rclone
    lin_rclone_config: /etc/rclone/rclone.conf
These two are rarely modified.

    lin_rclone_allow_nonroot: false
    lin_rclone_group_gid: 911
Ansible will create a unix group `rclone` with given Id. If `allow_nonroot`
is true, the remote user will be added in the group and consequently will
have read access to rclone configuration and non-root rclone mounts.

    lin_rclone_idle_timeout: 900
    lin_rclone_mount_timeout: 10
    lin_rclone_vfs_cache_mode: writes
    lin_rclone_dir_cache_time: 30s
    lin_rclone_mount_verb: mount, cmount, mount2 or none
The settings configure a few specific mount options.

    lin_rclone_bash_alias: true
Create command alias _rc_ in user profile.

    lin_rclone_mounts: []
List of mounts. Every mount is described by a dictionary explained below.

### Mount Item

    name: remote
The name of remote. Required.

    path: /mnt/remote
Mount point.
Required even if `mount` is `no` (it's then removed from fstab and systemd).

    enabled: true
Optional boolean, defaults to `true`. If false, ansible will just skip this item.

    config: |
      type = ...
      token = [TOKEN]
Plain-text remote section to be added in the rclone config file. The section may
contain a special placeholder `[TOKEN]` (literally), which will be replaced by
authorization for this remote.

    token: '{json...}'
Optional string containg authorizatin token for this remote in free format.
As this usually is a JSON dictionary, please wrap the string in single quotes
to avoid problems with Ansible YAML parser. 

    reuse_token: false
This can be true, false, empty string or name of the section in rclone config.
When this is false or empty string (the default), only the token configured
above will be given to remote (if present). If this is true, ansible will
look for a previous token in the config and prefer the one found. If non is
found, ansible will fall back to the literal token above. The previous
token is by default looked up in the same section as this remote name, but
you can provide a custom section name instead of true here.

    mount: true
Optional boolean. When true (the default), the mount will be added to
fstab or systemd. When false, the mount entry will be removed (if found).

    systemd: <depends on lin_rclone_prefer_systemd>
Optional boolean, defaults to `lin_rclone_prefer_systemd`.
If true, a systemd unit will be created.
If false, a fstab line will be added.

    automount: false
Optional boolean, defaults to false. If true, the systemd automounter will
be enabled for the corresponding fstab entry.

    nonroot: false
Normally rclone mounts are only accessible to root. If `nonroot` is true,
the mount will be read-only accessible by the members of group `rclone`.

    bglog: false
If true, the background rclone process will dump a debugging log in /tmp.

    proxy: proto://host:port
Optional proxy, protocol is one of `http`,`https`,`socks`,`socks5`.

## Tags

- `lin_rclone_install` -- install rclone
- `lin_rclone_wrapper` -- create fuse wrapper for mount
- `lin_rclone_config` -- add remotes in config file
- `lin_rclone_mounts` -- create fstab/systemd entries and configure automount
- `lin_rclone_bashrc` -- create bash alias for rclone
- `lin_rclone_docker_plugin` -- setup rclone docker plugin
- `lin_rclone_all` -- all of the above


## Dependencies

This role pulls the `reload systemd daemon` handler from role `ivansible.lin_base`.


## Example Playbook

    - hosts: mystorage
      roles:
         - role: ivansible.lin_rclone
           lin_rclone_allow_nonroot: true
           lin_rclone_mounts:
           - name: box
             path: /mnt/box
             token: "my_box_token"
             reuse_token: another_box_section  # (or just true)
             automount: true
             nonroot: true
             config: |
               type = box
               token = [TOKEN]


## License

MIT

## Author Information

Created in 2019-2021 by [IvanSible](https://github.com/ivansible)
