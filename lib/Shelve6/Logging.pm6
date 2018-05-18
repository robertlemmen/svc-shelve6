unit class Shelve6::Logging;

has $.ctx;

my $max-ctx-width = 0;

my $date-fmt = sub ($self) {
    given $self {
        sprintf "%04d/%02d/%02d %02d:%02d:%06.3f",
            .year, .month, .day,
            .hour, .minute, .second
    }
}

my sub log($severity, $ctx, $msg) {
    say   DateTime.now(formatter => $date-fmt)
        ~ " ["
        ~ sprintf('%-' ~ $max-ctx-width ~ 's', $ctx)
        ~ "] ["
        ~ sprintf('%-5s', $severity) ~ "] $msg";
}

method new($ctx) {
    if ($ctx.chars > $max-ctx-width) {
        $max-ctx-width = $ctx.chars;
    }
    return self.bless(ctx => $ctx);
}

method trace($msg) {
    log('trace', $!ctx, $msg);
}

method debug($msg) {
    log('debug', $!ctx, $msg);
}

method info($msg) {
    log('info', $!ctx, $msg);
}

method warn($msg) {
    log('warn', $!ctx, $msg);
}

method error($msg) {
    log('error', $!ctx, $msg);
}

