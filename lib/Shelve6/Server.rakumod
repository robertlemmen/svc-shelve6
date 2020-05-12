use Cro::HTTP::Router;
use Cro::HTTP::Server;
use JSON::Fast;

use Shelve6::Logging;
use Shelve6::AuthInfo;

use X::Shelve6::ClientError;

unit class Shelve6::Server;

has $.port;
has $.base-url;
has $.authentication;
has $!http-service;
has %!repositories;

my $log = Shelve6::Logging.new('server');

my class AuthTokenToRolesResolver does Cro::HTTP::Middleware::Request {
    has $.authentication;
    method process(Supply $requests --> Supply) {
        supply whenever $requests -> $request {
            my $auth-header = $request.header('Authorization')//'';
            if $auth-header ~~ /^ 'Bearer ' $<token>=[\w+] $/ {
                for @($!authentication<opaque-tokens>) -> $token-config {
                    if $token-config<token> eq $<token> {
                        $request.auth = Shelve6::AuthInfo.new(
                            owner => $token-config<owner>,
                            roles => @($token-config<roles>));
                        last;
                    }
                }
            }
            emit $request;
        }
    }
}

method register-repo($name, $repo) {
    %!repositories{$name} = $repo;
}

# this wraps a route handler block and adds logic to convert exceptions
# to error responses
sub with-api-exceptions(&route-handler) {
    &route-handler();
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

method start() {
    my $repo-routes = route {
        before-matched AuthTokenToRolesResolver.new(:$!authentication);

        get -> $repo-name {
            redirect "/repos/$repo-name/packages.json";
        }
        get -> $repo-name, 'packages.json' {
            with-api-exceptions({
                if %!repositories{$repo-name}:exists {
                    content 'application/json', to-json(
                        %!repositories{$repo-name}.get-package-list(request.auth),
                        :sorted-keys);
                }
                else {
                    not-found;
                }
            })
        }
        get -> $repo-name, *@path {
            with-api-exceptions({
                if %!repositories{$repo-name}:exists {
                    my $path = %!repositories{$repo-name}.get-file(
                                    @path.join('/'),
                                    request.auth);
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
            })
        }
        post -> $repo-name {
            with-api-exceptions({
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
                                %!repositories{$repo-name}.put-file(
                                        $part.filename,
                                        $part.body-blob,
                                        request.auth);
                            }
                            else {
                                forbidden;
                                content("text/plain", "part name of upload must be 'artifact'");
                            }
                        }
                    }
                }
                else {
                    not-found;
                }
            })
        }
    };

    my $top-router = route {
        include 'repos' => $repo-routes;
    };

    $!http-service = Cro::HTTP::Server.new(
        :host('localhost'), :port($!port), :application($top-router));
    $!http-service.start;

    $log.debug("HTTP server listening on port $!port");
}

method stop() {
    $!http-service.stop;
}
