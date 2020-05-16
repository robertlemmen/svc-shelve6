unit module StepDefs;

use CucumisSextus::Glue;
use Temp::Path;

my $shelve6-proc;
my $shelve6-promise;
my $temp-path;
my $orig-cwd;
my $upload-exitcode;
my $artifact-name;
my $base-url;

# XXX a small helper sub that runs a process with timeout and stdout/stderr
# printing, plus stdout introspection

Step /'a running shelve6 service with sample config "' (<[\w]+[.-]>+) '"'/, sub ($filename) {
    $orig-cwd = $*CWD;
    $temp-path = make-temp-dir;
    chdir($temp-path);

    $shelve6-proc = Proc::Async.new("$orig-cwd/bin/shelve6", 
        "--config-file=$orig-cwd/features/files/$filename");
    my $ready-promise = Promise.new();

    $shelve6-proc.stdout.lines.tap(-> $m {
        diag "shelve6 stdout: $m";
        if $m ~~ /'reachable under \'' $<base-url>=[ 'http://' <-[']>+ ] '\''/ {
            $base-url = $<base-url>;
        }
        if $m ~~ /'Application initialization complete!'/ {
            $ready-promise.keep;
        }
    }); 
    $shelve6-proc.stderr.lines.tap(-> $m {
        diag "shelve6 stderr: $m";
    });

    $shelve6-promise = $shelve6-proc.start;
    
    await $ready-promise;
}

Step /'sending sample artifact "' (<[\w]+[.-]>+) '" via shelve6-upload'/, sub ($filename) {
    $artifact-name = $filename;
    my $upload-proc = Proc::Async.new("$orig-cwd/bin/shelve6-upload", 
        "$orig-cwd/features/files/$filename", $base-url);

    $upload-proc.stdout.lines.tap(-> $m {
        diag "shelve6-upload stdout: $m";
    }); 
    $upload-proc.stderr.lines.tap(-> $m {
        diag "shelve6-upload stderr: $m";
    });

    my $ret = await $upload-proc.start;
    $upload-exitcode = $ret.exitcode;
}

Step /'the upload returned exit code ' (\d+)/, sub ($code) {
    if $upload-exitcode != $code {
        die "Exit code from shelve6-upload is $upload-exitcode, expected was $code";
    }
}

Step /'"zef info" now shows a source-url matching the shelve6 config'/, sub {
    my $zef-config-text = "$orig-cwd/features/files/zef-config.json".IO.slurp;
    $zef-config-text.subst(/'<TEMP_PATH>'/, $temp-path.absolute, :g);
    "$temp-path/zef-config.json".IO.spurt($zef-config-text);
    
    my $zef-proc = Proc::Async.new("zef", "--config-path=$temp-path/zef-config.json",
                    "info", "Foo::Sample");

    my $source-url = '';
    $zef-proc.stdout.lines.tap(-> $m {
        diag "zef stdout: $m";
        if $m ~~ /^ 'Source-url:' \s+ $<source-url>=[ 'http://' .* ] / {
            $source-url = $<source-url>;
        }
    }); 
    $zef-proc.stderr.lines.tap(-> $m {
        diag "zef stderr: $m";
    });

    await $zef-proc.start;

    if $source-url ne "$base-url/$artifact-name" {
        die "zef did not have correct source-url for uploaded artifact";
    }
}

After sub ($feature, $scenario) {
    $shelve6-proc.kill(Signal::SIGINT);
    await $shelve6-promise;
    chdir($orig-cwd);
}
