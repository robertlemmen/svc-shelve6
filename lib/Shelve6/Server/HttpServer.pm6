use Cro;
use Cro::HTTP::Request;
use Cro::HTTP::RequestParser;
use Cro::HTTP::Response;
use Cro::HTTP::ResponseSerializer;
use Cro::HTTP::Router;
use Cro::TCP;

use Shelve6::Server;

unit class Shelve6::Server::HttpServer does Shelve6::Server does Cro::Transform;

has $!port;
has $!http-service;
has %!repositories;

method configure(%options) {
    # XXX validate and more options
    $!port = %options<port>;
}

method register-repo($name, $repo) {
    %!repositories{$name} = $repo;
}

method start() {
    $!http-service = Cro.compose(
        # XXX this weird ipv6 binding thing..
        Cro::TCP::Listener.new(host => '0.0.0.0', port => $!port),
        Cro::HTTP::RequestParser.new,
        self,
        Cro::HTTP::ResponseSerializer.new
    );
    $!http-service.start;
    say %!repositories.perl;
}

method stop() {
    $!http-service.stop;
}

method consumes() { Cro::HTTP::Request }

method produces() { Cro::HTTP::Response }

method transformer($request-stream) {
    supply {
        whenever $request-stream -> $request {
            my $parts = $request.path-segments;
            if $parts[0] eq '' {
                say "root rq, forward";
            }
            elsif $parts[0] eq 'repos' {
                if %!repositories{$parts[1]}:exists {
                    say "repos rq!";
                    %!repositories{$parts[1]}.handle-repo-rq($request, 2).emit;
                }
                else {
                    say "repos rq, but no repo found";
                }
            }
            else {
                say "unknown";
                say "Request to " ~ $request.path-segments.perl;
                given Cro::HTTP::Response.new(:200status) {
                    .append-header('Content-type', 'application/json');
                    .set-body('woohoo');
                    .emit;
                }
            }
        }
    }
}
