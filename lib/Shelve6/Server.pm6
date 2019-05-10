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
        get -> 'repos', $repo-name {
            redirect "/repos/$repo-name/packages.json";
        }
        get -> 'repos', $repo-name, 'packages.json' {
            if %!repositories{$repo-name}:exists {
                content 'application/json', to-json %!repositories{$repo-name}.get-package-list();
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
                    #  make sure it is a Cro::HTTP::Body::MultiPartFormData
                    # with one entry named "artifact"
                    if ! $object ~~ Cro::HTTP::BodyParser::MultiPartFormData.WHAT {
                        die "not multi-part form data";
                    }
                    for $object.parts -> $part {
                        if $part.name eq 'artifact' {
                            $log.debug("upload of artifact '{$part.filename}', {$part.body-blob.elems} octets");
                            %!repositories{$repo-name}.put($part.filename, $part.body-blob);
                        }
                        else {
                            # warn, ignore
                        }
                    }
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
