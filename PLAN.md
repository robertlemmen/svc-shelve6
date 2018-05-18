The idea here is to build a repository service that perl6 modules, but also
other stuff, can be pushed to and pulled via the usual means. This would e.g. be
useful for a corporation doing perl6 development that do not want all their code
in the open.

Basic requirements:
- push a module tarball
- download and install via zef
- authentication for upload/download

Further requirements and nice-to-have:
- multiple logical repos
- UI to browse and manage
- API to manage and automate
- local cache/proxy for other repositories

Ideas:
- web service
- /ui/ /api/ and /repos
- /repos/<reponame> to support multiple logical repos
- post to the repo to submit a tarball
- get list from repo in cpan format /repos/<reponame>/packages.json
- entries in there are enriched meta files from tarball
- submission means a few steps to extract/verify
- flat-file structure without db, startup of service collects info
- future: multiple instances on same backend filesystem by writing update log
  files each
- pluggable authentication
- put all files in common root, so that at least the tarballs can be delivered 
  directly with reverse proxy
- perl6 repos can eitehr be local ones, or proxy ones where a cronjob fetches the
  remote/backing updates and stores them locally. from the client side these
  look the same. could have a "cached" type as well which does only store
  artifacts locally if they ever get accessed

Details:
- cro as web server
- tls and direct access to static files through nginx or similar
- X-accel to serve from nginx, with authentication
- local store with artifacts, state and config in flat files, so they can be
  shared and rsynced. needs write to temp and move for atomicity
- nice logging and statistics keeping
- pluggable and configurable expiry of old versions within cpan repo type
- pluggable repository types

