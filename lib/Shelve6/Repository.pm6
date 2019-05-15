use Cro::HTTP::Response;
use JSON::Fast;

use Shelve6::Logging;
use Shelve6::Server;
use Shelve6::Store;

unit class Shelve6::Repository;

has Str $!name;
has Str $!base-url;
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
    $!base-url = $!server.base-url;
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
    my $proc = run(<tar --list -z -f - >, :out, :in);
    $proc.in.write($blob);
    $proc.in.close;
    my $out = $proc.out.slurp-rest();
    my $meta-membername;
    for $out.lines -> $l {
        if $l.ends-with('META6.json') || $l.ends-with('META6.info') {
            $meta-membername = $l;
        }
    }
    if ! defined $meta-membername {
        # XXX refuse
    }
    $proc = run(qqw{tar --get --to-stdout -z -f - $meta-membername}, :out, :in);
    $proc.in.write($blob);
    $proc.in.close;
    my $meta-json = $proc.out.slurp-rest();
    # XXX parse json, refuse if not valid
    # XXX in the future also perform checks on it
    $!store.put($!name, $filename, $blob, $meta-json);
}

method get-package-list() {
    my $packages = $!store.list-artifacts($!name);
    my @result-list;
    for $packages -> $p {
        my $meta-json = $!store.get-meta($!name, $p);
        my $meta = from-json($meta-json);
        $meta{"source-url"} = "$!base-url/repos/$!name/$p";
        @result-list.push($meta);
    }
    # XXX cache them by mtime 
    $log.debug(" --> found {@result-list.perl}");
    return @result-list;
}

method get-file($path) {
    # XXX check that artifact exists, return undef otehrwise
    return $path;
}
