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

sub run-helper(:$name, :$command, :&stdout-callback) {
    my $proc = Proc::Async.new($command.split(' '));

    $proc.stdout.lines.tap(-> $m {
        diag "$name stdout: $m";
        if &stdout-callback {
            &stdout-callback($m);
        }
    });
    $proc.stderr.lines.tap(-> $m {
        diag "$name stderr: $m";
    });

    return $proc;
}

Step /'a running shelve6 service with sample config "' (<[\w]+[.-]>+) '"'/, sub ($filename) {
    $orig-cwd = $*CWD;
    $temp-path = make-temp-dir;
    chdir($temp-path);

    my $ready-promise = Promise.new();
    $shelve6-proc = run-helper(
                name => "shelve6",
                command => "$orig-cwd/bin/shelve6 --config-file=$orig-cwd/features/files/$filename",
                stdout-callback => sub ($m) {
                    if $m ~~ /'reachable under \'' $<base-url>=[ 'http://' <-[']>+ ] '\''/ {
                        $base-url = $<base-url>;
                    }
                    if $m ~~ /'Application initialization complete!'/ {
                        $ready-promise.keep;
                    }
            });
    $shelve6-promise = $shelve6-proc.start;

    await $ready-promise;
}

Step /'sending sample artifact "' (<[\w]+[.-]>+) '" via shelve6-upload' ' and having no token set'?/, sub ($filename) {
    $artifact-name = $filename;
    my $upload-proc = run-helper(
                name => "shelve6-upload",
                command => "$orig-cwd/bin/shelve6-upload $orig-cwd/features/files/$filename $base-url");

    my $ret = await $upload-proc.start;
    $upload-exitcode = $ret.exitcode;
}

Step /'sending sample artifact "' (<[\w]+[.-]>+) '" via shelve6-upload and token set to \'' (<[\w]>+) '\''/, sub ($filename, $token) {
    $artifact-name = $filename;
    my $upload-proc = run-helper(
                name => "shelve6-upload",
                command => "$orig-cwd/bin/shelve6-upload --opaque-token=$token $orig-cwd/features/files/$filename $base-url");

    my $ret = await $upload-proc.start;
    $upload-exitcode = $ret.exitcode;
}

Step /'the upload returned exit code ' (\d+)/, sub ($code) {
    if $upload-exitcode != $code {
        die "Exit code from shelve6-upload is $upload-exitcode, expected was $code";
    }
}

Step /'the upload returned a non-zero exit code'/, sub () {
    if $upload-exitcode == 0 {
        die "Exit code from shelve6-upload is 0, was expecting non-zero";
    }
}

sub zef-info-step($token, $want-source) {
    my $zef-config-text = "$orig-cwd/features/files/zef-config.json".IO.slurp;
    $zef-config-text.subst(/'<TEMP_PATH>'/, $temp-path.absolute, :g);
    "$temp-path/zef-config.json".IO.spurt($zef-config-text);

    my $source-url = '';
    my $zef-proc = run-helper(
                name => "zef",
                command => "zef --config-path=$temp-path/zef-config.json info Foo::Sample",
                stdout-callback => sub ($m) {
                    if $m ~~ /^ 'Source-url:' \s+ $<source-url>=[ 'http://' .* ] / {
                        $source-url = $<source-url>;
                    }
                });

    CATCH {
        when X::Proc::Unsuccessful {
            # this is fine, we only care whether we do get a source-url or not
            diag .message
        }
    }

    if $token {
        await $zef-proc.start(ENV => %*ENV.append('SHELVE6_OPAQUE_TOKEN' => $token));
    }
    else {
        await $zef-proc.start;
    }

    if $want-source {
        if $source-url ne "$base-url/$artifact-name" {
            die "zef did not have correct source-url for uploaded artifact";
        }
    }
    else {
        if $source-url eq "$base-url/$artifact-name" {
            die "zef did have source-url for uploaded artifact, unexpected";
        }
    }
}

Step /'"zef info" now shows a source-url matching the shelve6 config'/, sub {
    zef-info-step(Nil, True);
}

Step /'"zef info" without token does not show a source-url matching the shelve6 config'/, sub {
    zef-info-step(Nil, False);
}

Step /'"zef info" with token \'' (<[\w]>+) '\' does not show a source-url matching the shelve6 config'/, sub ($token) {
    zef-info-step($token, False);
}

Step /'"zef info" with token \'' (<[\w]>+) '\' now shows a source-url matching the shelve6 config'/, sub ($token) {
    zef-info-step($token, True);
}

After sub ($feature, $scenario) {
    $shelve6-proc.kill(Signal::SIGINT);
    await $shelve6-promise;
    chdir($orig-cwd);
}
