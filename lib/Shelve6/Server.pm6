use Cro;
use Cro::HTTP::Request;
use Cro::HTTP::RequestParser;
use Cro::HTTP::Response;
use Cro::HTTP::ResponseSerializer;
use Cro::HTTP::Router;
use Cro::TCP;

use Shelve6::Logging;

unit class Shelve6::Server;

has $!port;
has $!http-service;
has %!repositories;

my $log = Shelve6::Logging.new('server');

method configure(%options) {
    # XXX validate and more options
    $!port = %options<port>;
}

method register-repo($name, $repo) {
    %!repositories{$name} = $repo;
}

method start() {
    my $router = route {
        get -> 'repos', $repo-name, 'packages.json' {
            if %!repositories{$repo-name}:exists {
                content 'application/json', %!repositories{$repo-name}.get-package-list();
            }
            else {
                # fancy body
                not-found;
            }
        }
        get -> 'repos', $repo-name, *@path {
            if %!repositories{$repo-name}:exists {
                my $path = %!repositories{$repo-name}.get-file(@path.join('/'));
                # XXX configurably serve through nginx directly
                static $path;
            }
            else {
                # fancy body
                not-found;
            }
        }
        post -> 'repos', $repo-name {
            if %!repositories{$repo-name}:exists {
                request-body -> $object {
                    # XXX make sure it is a Cro::HTTP::Body::MultiPartFormData
                    # with one entry
                    say $object.WHAT;
                    for $object.parts -> $part {
                        say "- {$part.name} {$part.filename} {$part.body-blob.elems}";
                    }
                    # XXX get file into tmpdir and call repo to handle it
                }
            }
            else {
                not-found;
            }
        }
    };

    $!http-service = Cro.compose(
        # XXX this weird ipv6 binding thing..
        Cro::TCP::Listener.new(host => '0.0.0.0', port => $!port),
        Cro::HTTP::RequestParser.new,
        $router,
        Cro::HTTP::ResponseSerializer.new
    );
    $!http-service.start;

    $log.debug("HTTP server listening on port $!port");
}

method stop() {
    $!http-service.stop;
}
