use Cro::HTTP::Response;

use Shelve6::Logging;
use Shelve6::Server;
use Shelve6::Store;

unit class Shelve6::Repository;

has Str $!name;
has Shelve6::Server $!server;
has Shelve6::Store $!store;

my $log = Shelve6::Logging.new('repo');

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
    $log.debug("Setting up repository '$!name'");
}

method stop() {
}

method put($filename, $blob) {
    # a bit primitive, but there you go for now
    # XXX check, mangle name, check for duplicates...
    # XXX extract META and put next to actual file
    my $proc = run(<tar --list -f - >, :out, :in);
    $proc.in.IO.write($blob);
    $proc.in.IO.close;
    my $out = |$proc.out.slurp-rest();
    say("## #out");
    $!store.put($!name, $filename, $blob);
}

method get-package-list() {
    my $packages = $!store.list-artifacts($!name);
    $log.debug(" --> found {$packages.perl}");
    return $packages;
}

method get-file($path) {
    return $path;
}
