Feature: Basic up- and download
    The very simple upload via the provided script and download via zef should 
    work as desired and documented

Scenario: Initial upload of good artifact
    Given a running shelve6 service with sample config "basic1.yaml"
    And sending sample artifact "raku-foo-sample-0.1.tar.gz" via shelve6-upload
    Then the upload returned exit code 0
    And "zef info" now shows a source-url matching the shelve6 config

Scenario: Upload of duplicate artifact
    Given a running shelve6 service with sample config "basic1.yaml"
    And sending sample artifact "raku-foo-sample-0.1.tar.gz" via shelve6-upload
    Then the upload returned exit code 0
    And sending sample artifact "raku-foo-sample-0.1.tar.gz" via shelve6-upload
    Then the upload returned a non-zero exit code

Scenario: Upload of artifact without META6.json should fail
    Given a running shelve6 service with sample config "basic1.yaml"
    And sending sample artifact "raku-foo-sample-nometa.tar.gz" via shelve6-upload
    Then the upload returned a non-zero exit code

Scenario: Upload of artifact with broken META6.json should fail
    Given a running shelve6 service with sample config "basic1.yaml"
    And sending sample artifact "raku-foo-sample-broken.tar.gz" via shelve6-upload
    Then the upload returned a non-zero exit code
