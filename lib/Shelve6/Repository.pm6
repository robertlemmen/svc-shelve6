use Shelve6::Component;

unit role Shelve6::Repository does Shelve6::Component;

method register-server($server) { ... }

method register-store($store) { ... }

method handle-repo-rq($request, $path-segments-handled) { ... }
