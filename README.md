Shelve6
-------

... A artifact repository for the raku language and friends

The goal is to build a artifact repository service that raku modules, but also
other stuff, can be pushed to and pulled via the usual means (i.e. pushed from
CI or manual workflows, pulled via zef). This would be useful for an organisation 
doing raku development, does not want all their code publicly available, 
yet want to use a regular module-centric, tarball/release-based development flow.

Essentially this is a "content storage" service as described in [S22][1]

## Features

- Upload Raku modules
- Fetch with zef
- Authentication
- Multiple configurable logical repos

## Upcoming and ToDo

- cucumis sextus tests
- UI to browse and manage
- API to manage and automate
- Local cache/proxy for other repositories, like CPAN. Could be just a cache,
  or a fetch-ahead full copy. Perhaps both, configurably.
- Rarification/expiry of artifacts in configured repositories
- Web hooks for automation
- Verification and other plugins
- Shared file store, multiple shelve6 instances. Or a database as a store.
- More auth types
- Full-blown monitoring, resilience etc 
- More metadata, like when uploaded and by whom. "on-behalf" in upload script 
  so that a CI or automation job can say on whose command they uploaded

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

## Authentication and Authorization

If you want to use the repository for private code, it may be a good idea to
enable some security on it. Shelve6 can use credentials in the request and map
them to a set of roles associated with that credential. Currently the only
credential type supported are 'opaque' tokens, these are just striings that are
not looked into (so not JWT or so). These come in a HTTP header like
`Authorization: Bearer supersecret`, where 'supersecret' is the credential. In
the future more credential types can be supported. To configure the mapping of 
credentials to roles, extend the 'server' part of the configuration:
```
server:
    port: 8080
    base-url: "http://localhost:8080"
    authentication:
        opaque-tokens:
            - token: supersecret
              roles: [CI]
              owner: raku-ci-1
            - token: eng8ahquia2kungeitaequie
              roles: [DEV, ADMIN]
              owner: Max Mustermann <mmustermann@megacorp.com>
```
In order to actually require any roles, you need to configure which roles allow
what operation, on the repository:
```
repositories:
    - name: p6repo
      authorization:
        upload: [CI, DEV, ADMIN]
        download: [CI, DEV, ADMIN]
        delete: [ADMIN]
```
Note that the credential is associated with all the roles from the server
config, but any role in the repository section is sufficient for access to be
granted. For example the credential 'eng8ahquia2kungeitaequie' above gives both
the 'DEV' and the 'ADMIN' roles, any of which would be enough to upload and
download artifacts.

The shelve6-upload script supports setting these tokens through a commandline
argument or an environment variable.

In order to enable zef to provide credentials during module fetching, you need
to install the `Zef::Service::AuthenticatedDownload` plugin:
```
    zef install Zef::Service::AuthenticatedDownload
```
And configure it. The zef README explains where you can find the zef config, 
where you can add the
plugin and configure it, which is best done before the other web fetchers to
avoid them trying to download and failing due to auth:

```
        {
            "short-name" : "authenticated-download",
            "module" : "Zef::Service::AuthenticatedDownload",
            "options" : { 
                "configured-hosts" : [
                    {
                        "hostname" : "localhost",
                        "auth-type" : "opaque-token",
                        "token" :  "supersecret"
                    }
                ]
            }
        },
```
This will make zef use the configured credential for the host in question. If
you do not want to put the credential into the config file, you can also leave
it out and supply it via the ZEF_AUTH_OPAQUE_TOKEN environment variable.

## License

Shelve6 is licensed under the [Artistic License 2.0](https://opensource.org/licenses/Artistic-2.0). 

## Feedback and Contact

Please let me know what you think: Robert Lemmen <robertle@semistable.com>

[1]: https://design.raku.org/S22.html#content_storage
