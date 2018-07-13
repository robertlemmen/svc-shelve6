unit class Shelve6::Repository::CPAN;

has $!name;
has $!server;
has $!store;

method configure(%options) {
    # XXX validate and more options
    $!name = %options<name>;
}

method set-server($server) {
    $!server = $server;
}

method set-store($store) {
    $!store = $store;
}

method start() {
}

method stop() {
}