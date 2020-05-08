Shelve6
-------

... A artifact repository for the raku language and friends

The goal is to build a artifact repository service that raku modules, but also
other stuff, can be pushed to and pulled via the usual means (i.e. pushed from
CI or manual workflows, pulled via zef). This would be useful for an organisation 
doing raku development, does not want all their code publicly available, 
yet want to use a regular module-centric, tarball/release-based development flow.

Essentially this is a "content storage" service as described in [S22][1]

## Basic requirements

- push a module tarball
- extract META6.json, augment with correct/new source-url and combine into 
  distribution list
- download and install via zef
- authentication for upload/download

## Further requirements and nice-to-have

- multiple configurable logical repos
- UI to browse and manage
- API to manage and automate
- Local cache/proxy for other repositories, like CPAN. Could be just a cache,
  or a fetch-ahead full copy. Perhaps both, configurably.
- Rarification/expiry of artifacts in configured repositories

## Random Ideas

- web service
- /ui/ /api/ and /repos
- /repos/<reponame> to support multiple logical repos
- post to the repo to submit a tarball, possibly as form-encoded
- get list from repo in cpan format /repos/<reponame>/packages.json
- entries in there are enriched meta files from tarball
- submission means a few steps to extract/verify, we can then later have plugins
  that do whatever people want in terms of checking/gating/analysis.
- flat-file structure without db, startup of service collects info. Later we
  could have a more complicated persistence
- e.g.: multiple instances on same backend filesystem by writing update log
  files each
- pluggable authentication, could be different mechanism for people and CI jobs 
- put all files in common root, so that at least the tarballs can be delivered 
  directly with reverse proxy
- perl6 repos can either be local ones, or proxy ones where a cronjob fetches the
  remote/backing updates and stores them locally. from the client side these
  look the same. could have a "cached" type as well which does only store
  artifacts locally if they ever get accessed
- some sort of subscribale event/webhook when modules get uploaded to allow
  other automation to run
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
- full-blown monitoring, resilience etc 
- more metadata, like when uploaded and by whom. "on-behalf" in upload script 
  so that a CI or automation job can say on whose command they uploaded

## ToDo

* upload auth with bearer tokens
* patch zef to auth downloads with bearer token

Also grep for the `XXX` fixmes in the code!

## Usage

Shelve6 comes as a web service that you can just start e.g. directly from
the checked-out source repository via `RAKUDOLIB=lib bin/shelve6`, or if it is 
properly installed just via `shelve6`. It reads a config.yaml file, a simple
sample is included, and might look like this:
```
    server:
        port: 8080
        base-url: "http://localhost:8080"
    store:
        basedir: store
    repositories:
        - name: p6repo
```
* `base-url` is where you want the service to be found externally
* `port` is of course the port the service listens on, note that  it currently
  only binds to the first localhost interface, let me know if that gives you grief.
* `basedir` is a directory where shleve6 will store the artifacts
* and the repositories is a list of logical artifact repositories in which you
  can store modules

With the service running, you can use the supplied shelve6-upload script to put
artifacts into shelve6:
```
    bin/shelve6-upload raku-foo-bar-0.1.tar.gz http://localhost:8080/repos/p6repo

```
This script is just a thin wrapper around curl, you just need a multipart form
post really.

In order to fetch artifacts, you need to configure your zef to recognise the
repository. In my case I have a `~/.config/zef/config.json`, where in the
`Repository` section I added:
```
    {
        "short-name" : "shelve6",
        "enabled" : 1,
        "module" : "Zef::Repository::Ecosystems",
        "options" : {
            "name" : "shelve6",
            "auto-update" : 1,
            "mirrors" : [
                "http://localhost:8080/repos/p6repo/packages.json"
            ]
        }
    },
```
After that, zef happily pulls from shelve6!

## License

Shelve6 is licensed under the [Artistic License 2.0](https://opensource.org/licenses/Artistic-2.0). Note that the currently used Config module is GPL.

## Feedback and Contact

Please let me know what you think: Robert Lemmen <robertle@semistable.com>

[1]: https://design.raku.org/S22.html#content_storage
