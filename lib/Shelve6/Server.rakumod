use Cro;
use Cro::HTTP::Request;
use Cro::HTTP::RequestParser;
use Cro::HTTP::Response;
use Cro::HTTP::ResponseSerializer;
use Cro::HTTP::Router;
use Cro::TCP;
use JSON::Fast;

use Shelve6::Logging;
use X::Shelve6::ClientError;

unit class Shelve6::Server;

has $!port;
has $.base-url;
has $!http-service;
has %!repositories;

my $log = Shelve6::Logging.new('server');

method configure(%options) {
    # XXX validate and more options
    $!port = %options<port>;
    $!base-url = %options<base-url>;
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
                content 'application/json', to-json(%!repositories{$repo-name}.get-package-list(), :sorted-keys);
            }
            else {
                not-found;
            }
        }
        get -> 'repos', $repo-name, *@path {
            if %!repositories{$repo-name}:exists {
                my $path = %!repositories{$repo-name}.get-file(@path.join('/'));
                if defined $path {
                    # XXX configurably serve through nginx directly
                    static $path;
                }
                else {
                    not-found;
                }
            }
            else {
                not-found;
            }
        }
        post -> 'repos', $repo-name {
            if %!repositories{$repo-name}:exists {
                request-body -> $object {
                    #  make sure it is a Cro::HTTP::Body::MultiPartFormData
                    # with one entry named "artifact"
                    if ! $object ~~ Cro::HTTP::BodyParser::MultiPartFormData.WHAT {
                        forbidden;
                        content("text/plain", "artifact upload must be a MultiPartFormData");
                    }
                    for $object.parts -> $part {
                        if $part.name eq 'artifact' {
                            $log.debug("upload of artifact '{$part.filename}', {$part.body-blob.elems} octets");
                            %!repositories{$repo-name}.put($part.filename, $part.body-blob);
                        }
                        else {
                            forbidden;
                            content("text/plain", "part name of upload must be 'artifact'");
                        }
                    }
                }
                CATCH {
                    when X::Shelve6::ClientError {
                        response.status = .code;
                        content("text/plain", .message);
                    }
                    default {
                        $log.warn("Unhandled exception: " ~ .message);
                        $log.warn(.backtrace);
                        response.status = 500;
                        content("text/plain", .message);
                    }
                }                    
            }
            else {
                not-found;
            }
        }
    };

    $!http-service = Cro.compose(
        # XXX this weird ipv6 binding thing! perhaps it needs 
        # configuration? what heppens if I bind to ::1 on a machine that 
        # has no IPv6? can I have multiple listeners?
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
