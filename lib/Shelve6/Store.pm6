use Shelve6::Logging;

unit class Shelve6::Store;

has $!basedir;

my $log = Shelve6::Logging.new('store');

method configure(%options) {
    # XXX validate and more options
    $!basedir = %options<basedir>;
}

method start() {
    $log.debug("Setting up store with file backend at $!basedir");
}

method stop() {
}
