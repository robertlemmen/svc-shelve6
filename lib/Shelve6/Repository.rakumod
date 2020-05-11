use Cro::HTTP::Response;
use JSON::Fast;

use Shelve6::Logging;
use Shelve6::Server;
use Shelve6::Store;
use X::Shelve6::ClientError;

unit class Shelve6::Repository;

has Str $!name;
has $!authorization;
has Str $!base-url;
has Shelve6::Server $!server;
has Shelve6::Store $!store;

my $log = Shelve6::Logging.new('repo');

method configure(%options) {
    # XXX validate and more options
    $!name = %options<name>;
    $!authorization = %options<authorization>;
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
    $log.debug("Setting up repository '$!name', reachable under '$!base-url/repos/$!name'");
    for ('upload', 'download') -> $perm {
        my $roles = $!authorization{$perm} // ();
        if not $roles {
            $log.warn("No roles are required to '$perm' to $!name, this feels unsafe");
        }
    }
}

method stop() {
}

method !require-permission($perm, $auth-info) {
    my $sufficient-roles = set @($!authorization{$perm}) // ();
    my $present-roles = set ();
    my $owner-name = "unknown client";
    if $auth-info {
        $present-roles = set $auth-info.roles;
        $owner-name = $auth-info.owner;
    }

    if $sufficient-roles {
        if not $sufficient-roles (&) $present-roles {
            $log.debug("Denying $perm access on repo $!name to $owner-name");
            die X::Shelve6::ClientError.new(code => 403,
                message => "Denying $perm access, not authorized");
        }
    }
}

method put-file($filename, $blob, $auth-info) {
    self!require-permission("upload", $auth-info);
    # a bit primitive, but there you go for now
    my $proc = run(<tar --list -z -f - >, :out, :in);
    $proc.in.write($blob);
    $proc.in.close;
    my $out = $proc.out.slurp-rest();
    my $meta-membername;
    for $out.lines -> $l {
        # XXX ends-with? should be complete match
        if $l.ends-with('META6.json') || $l.ends-with('META6.info') {
            $meta-membername = $l;
        }
    }
    if ! defined $meta-membername {
        my $msg = "Artifact '$filename' seems to not contain a META6.json or .info, refusing";
        $log.warn($msg);
        # XXX is 403 the right code?
        die X::Shelve6::ClientError.new(code => 403, message => $msg);
    }
    
    $proc = run(qqw{tar --get --to-stdout -z -f - $meta-membername}, :out, :in);
    $proc.in.write($blob);
    $proc.in.close;
    my $meta-json = $proc.out.slurp-rest();
    try {
        my $parsed = from-json($meta-json);
        # XXX in the future also perform pluggable checks on it
    }
    if $! {
        my $msg = "Artifact '$filename' has malformed metadata, refusing";
        $log.warn($msg);
        # XXX is 403 the right code?
        die X::Shelve6::ClientError.new(code => 403, message => $msg);
    }
    $!store.put($!name, $filename, $blob, $meta-json);
}

method get-package-list($auth-info) {
    self!require-permission("download", $auth-info);
    # XXX cache the list?
    my $packages = $!store.list-artifacts($!name);
    my @result-list;
    for $packages -> $p {
        my $meta-json = $!store.get-meta($!name, $p);
        my $meta = from-json($meta-json);
        $meta{"source-url"} = "$!base-url/repos/$!name/$p";
        @result-list.push($meta);
    }
    $log.debug("fetch of package list from repo '$!name' with {@result-list.elems} entries");
    return @result-list;
}

method get-file($fname, $auth-info) {
    self!require-permission("download", $auth-info);
    if $!store.artifact-exists($!name, $fname) {
        $log.debug("fetch of artifact '$fname' from repo '$!name'");
        return $fname;
    }
    else {
        $log.debug("attempt to fetch non-existing artifact '$fname' from repo '$!name'");
        return Any;
    }
}
