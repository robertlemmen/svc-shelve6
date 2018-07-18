unit class Shelve6::Store;

has $!basedir;

method configure(%options) {
    # XXX validate and more options
    $!basedir = %options<basedir>;
}

method start() {
}

method stop() {
}
