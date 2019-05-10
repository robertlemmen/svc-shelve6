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

method put($path, $filename, $blob) {
    # XXX create path as required
    # XXX fail if already exists
    my $fh = open("$!basedir/$path/$filename", :w);
    $fh.write($blob);
    $fh.close;
    $log.debug("Stored artifact $path");
}

method list-artifacts($path) {
    my @results =  IO::Path.new("$!basedir/$path").dir;
    $log.debug("  got artifacts {@results.perl}");
    return @results.map(-> $i { $i.relative($!basedir)});
}
