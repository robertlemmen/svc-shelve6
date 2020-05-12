use Shelve6::Logging;
use X::Shelve6::ClientError;

unit class Shelve6::Store;

has $.basedir;

my $log = Shelve6::Logging.new('store');

method start() {
    $log.debug("Setting up store with file backend at '{$!basedir.IO.absolute}'");
}

method stop() {
}

method put($path, $filename, $blob, $meta) {
    if IO::Path.new("$!basedir/$path/artifacts/$filename").e {
        my $msg = "Attempt to replace artifact '$filename' in '$path', refusing";
        $log.warn($msg);
        die X::Shelve6::ClientError.new(code => 403, message => $msg);
    }
    # create path as required
    IO::Path.new("$!basedir/$path/artifacts/").mkdir;
    IO::Path.new("$!basedir/$path/meta/").mkdir;
    IO::Path.new("$!basedir/$path/temp/").mkdir;

    my $fh = open("$!basedir/$path/temp/$filename", :w);
    $fh.write($blob);
    $fh.close;
    "$!basedir/$path/temp/$filename".IO.rename("$!basedir/$path/artifacts/$filename");

    $fh = open("$!basedir/$path/temp/$filename.meta", :w);
    $fh.put($meta);
    $fh.close;
    "$!basedir/$path/temp/$filename.meta".IO.rename("$!basedir/$path/meta/$filename.meta");

    $log.debug("Stored artifact $filename in $path");
}

method list-artifacts($path) {
    my @results = IO::Path.new("$!basedir/$path/artifacts").dir;
    return @results.map(-> $i { $i.relative("$!basedir/$path/artifacts")});
}

method artifact-exists($path, $filename) {  
    return IO::Path.new("$!basedir/$path/artifacts/$filename").e;
}

method get-meta($path, $name) {
    my $fh = open("$!basedir/$path/meta/$name.meta");
    my $contents = $fh.slurp-rest;
    close $fh;
    return $contents;
}
