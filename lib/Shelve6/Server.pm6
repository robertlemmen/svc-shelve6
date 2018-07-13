use Cro;
use Cro::HTTP::Request;
use Cro::HTTP::RequestParser;
use Cro::HTTP::Response;
use Cro::HTTP::ResponseSerializer;
use Cro::TCP;

unit class Shelve6::Server;

has $!port;
has $!http-service;

method configure(%options) {
    # XXX validate and more options
    $!port = %options<port>;
}

class HTTPHello does Cro::Transform {
    method consumes() { Cro::HTTP::Request }
    method produces() { Cro::HTTP::Response }

    method transformer($request-stream) {
        supply {
            whenever $request-stream -> $request {
                say "Request to " ~ $request.path;
                given Cro::HTTP::Response.new(:200status) {
                    .append-header('Content-type', 'application/json');
                    .set-body('woohoo');
                    .emit;
                }
            }
        }
    }
}

method start() {
    $!http-service = Cro.compose(
        # XXX this weird ipv6 binding thing..
        Cro::TCP::Listener.new(host => '0.0.0.0', port => $!port),
        Cro::HTTP::RequestParser.new,
        HTTPHello,
        Cro::HTTP::ResponseSerializer.new
    );
    $!http-service.start;
}

method stop() {
    $!http-service.stop;
}

#
# 
# use Cro;
# use Cro::HTTP::Request;
# use Cro::HTTP::RequestParser;
# use Cro::HTTP::Response;
# use Cro::HTTP::ResponseSerializer;
# use Cro::TCP;
# use JSON::Fast;
# 
# 
# my $package-data = [{  "name" => "JSON::Hjson",
#                         "source-url" => "http://www.cpan.org/authors/id/A/AK/AKIYM/Perl6/JSON-Hjson-0.0.1.tar.gz",
#                         "perl" => "6.c",
#                         "resources" => [ ],
#                         "build-depends" => [ ],
#                         "depends" => [ ],
#                         "test-depends" => [
#                             "JSON::Tiny",
#                             "Test::META"
#                         ],
#                         "tags" => [ ],
#                         "provides" => {
#                             "JSON::Hjson" => "lib/JSON/Hjson.pm6",
#                             "JSON::Hjson::Grammar" => "lib/JSON/Hjson/Grammar.pm6",
#                             "JSON::Hjson::Actions" => "lib/JSON/Hjson/Actions.pm6"
#                         },
#                         "license" => "Artistic-2.0",
#                         "version" => "0.0.1",
#                         "description" => "Human JSON (Hjson) deserializer",
#                         "authors" => [
#                             "Takumi Akiyama"
#                         ]
#                     },
#                    ];
# 
# class HTTPHello does Cro::Transform {
#     method consumes() { Cro::HTTP::Request }
#     method produces() { Cro::HTTP::Response }
# 
#     method transformer($request-stream) {
#         supply {
#             whenever $request-stream -> $request {
#                 say "Request to " ~ $request.path;
#                 given Cro::HTTP::Response.new(:200status) {
#                     .append-header('Content-type', 'application/json');
#                     .set-body(to-json($package-data));
#                     .emit;
#                 }
#             }
#         }
#     }
# }
# 
# my Cro::Service $http-service = Cro.compose(
#     Cro::TCP::Listener.new( :host('localhost'), :port(8080) ),
#     Cro::HTTP::RequestParser.new,
#     HTTPHello,
#     Cro::HTTP::ResponseSerializer.new
# );
# 
# $http-service.start;
# signal(SIGINT).tap: {
#     note "Shutting down...";
#     $http-service.stop;
#     exit;
# }
# sleep;
# 
# 
