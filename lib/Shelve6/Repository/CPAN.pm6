use Cro::HTTP::Response;

use Shelve6::Repository;
use Shelve6::Server;
use Shelve6::Store;

unit class Shelve6::Repository::CPAN does Shelve6::Repository;

has Str $!name;
has Shelve6::Server $!server;
has Shelve6::Store $!store;

method configure(%options) {
    # XXX validate and more options
    $!name = %options<name>;
}

method register-server($server) {
    $!server = $server;
    $!server.register-repo($!name, self);
}

method register-store($store) {
    $!store = $store;
}

method start() {
}

method stop() {
}

method handle-repo-rq($request, $path-segments-handled) {
    my $response = Cro::HTTP::Response.new(:200status);
    $response.set-body('repo-rq!');
    return $response;
}
