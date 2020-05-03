Shelve6
-------

The idea here is to build a repository service that perl6 modules, but also
other stuff, can be pushed to and pulled via the usual means (i.e. zef). This 
could be useful for an organisation doing perl6 development that do not want 
all their code publicly available, yet want to use a regular module-centric
development flow.

Essentially this is a "content storage" service as described in [S22][1]

## Basic requirements:
- push a module tarball
- download and install via zef
- authentication for upload/download

## Further requirements and nice-to-have:
- multiple logical repos
- UI to browse and manage
- API to manage and automate
- local cache/proxy for other repositories, like CPAN

## Ideas
- web service
- /ui/ /api/ and /repos
- /repos/<reponame> to support multiple logical repos
- post to the repo to submit a tarball, possibly as form-encoded
- get list from repo in cpan format /repos/<reponame>/packages.json
- entries in there are enriched meta files from tarball
- submission means a few steps to extract/verify
- flat-file structure without db, startup of service collects info
- future: multiple instances on same backend filesystem by writing update log
  files each
- pluggable authentication, could be different mechanism for people and CI jobs 
- put all files in common root, so that at least the tarballs can be delivered 
  directly with reverse proxy
- perl6 repos can either be local ones, or proxy ones where a cronjob fetches the
  remote/backing updates and stores them locally. from the client side these
  look the same. could have a "cached" type as well which does only store
  artifacts locally if they ever get accessed
- some sort of event or pipeline to verify or test uploaded modules
- tls and direct access to static files through nginx or similar
- X-accel to serve from nginx, with authentication. not really needed but I
  would like to try that anyway
- local store with artifacts, state and config in flat files, so they can be
  shared and rsynced. needs write to temp and move for atomicity
- nice logging and statistics keeping
- configurable expiry of old versions in some cases (e.g. for snapshot builds
  from CI)
- zef would need local changes in ~/.config/zeff/config.json so that it knows
  about the store url, and it would need patches to support authentication

[1]: https://design.raku.org/S22.html#content_storage
