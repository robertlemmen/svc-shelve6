Feature: Up- and download with authentication
    Only permitted clients should be allowed to up/download artifacts if
    shelve6 is configured accordingly

Scenario: Upload attempt without authentification
    Given a running shelve6 service with sample config "auth1.yaml"
    And sending sample artifact "raku-foo-sample-0.1.tar.gz" via shelve6-upload and having no token set
    Then the upload returned a non-zero exit code

Scenario: Upload attempt with invalid token
    Given a running shelve6 service with sample config "auth1.yaml"
    And sending sample artifact "raku-foo-sample-0.1.tar.gz" via shelve6-upload and token set to 'aekuT9chauYidoda'
    Then the upload returned a non-zero exit code

Scenario: Upload attempt with valid token
    Given a running shelve6 service with sample config "auth1.yaml"
    And sending sample artifact "raku-foo-sample-0.1.tar.gz" via shelve6-upload and token set to 'ieng0aiCahJ9udai'
    Then the upload returned exit code 0

Scenario: Upload attempt with read-only token
    Given a running shelve6 service with sample config "auth1.yaml"
    And sending sample artifact "raku-foo-sample-0.1.tar.gz" via shelve6-upload and token set to 'Kael7ahngeithe4r'
    Then the upload returned a non-zero exit code

Scenario: Download attempt without authentication
    Given a running shelve6 service with sample config "auth1.yaml"
    And sending sample artifact "raku-foo-sample-0.1.tar.gz" via shelve6-upload and token set to 'ieng0aiCahJ9udai'
    Then the upload returned exit code 0
    And "zef info" without token does not show a source-url matching the shelve6 config

Scenario: Download attempt with valid token
    Given a running shelve6 service with sample config "auth1.yaml"
    And sending sample artifact "raku-foo-sample-0.1.tar.gz" via shelve6-upload and token set to 'Hoh5eishingievae'
    Then the upload returned exit code 0
    And "zef info" with token 'Kael7ahngeithe4r' now shows a source-url matching the shelve6 config

