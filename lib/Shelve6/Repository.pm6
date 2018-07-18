use Cro::HTTP::Response;

use Shelve6::Server;
use Shelve6::Store;

unit class Shelve6::Repository;

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

method get-package-list() {
    return %(test => [123, 456]);
}

method get-file($path) {
    return $path;
}
