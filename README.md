# RG Certificate Authority Helper

This is a work in progress experiment to make generating self-signed SSL certificates
easier to manage.

# Features

- Quick "show cert info": "rgca cert show FILE" (as opposed to "openssl x509 -in FILE -noout -text").
- Rich command-line and config file to control cert generation.
- Pre/post scripts to manage certs (say, deploying them to a server, committing
  serial/index to git)
- Config groups so you can easily select between sets of configs (`rgca --type
  corporate cert new www.example.com` vs. `--type developer`).
- Everything can be controlled by command line arguments.  (`rgca cert new
  --valid-days 365 --bits 1024 --OU WidgetUnit`, see "rgca cert new --help" below).

## Requirements

- Python 3 (possibly 3.6 or newer)
- Python typer library
- pyopenssl

For example on Ubuntu: `sudo apt install python3 python3-pip python3-pyopenssl; pip3 install typer`

## Status

What works:

  - The "cert new" command is fully implemented for server certs.
  - "cert new" is compatible with openssl CLI generated CAs (cert, key, index, serial).
  - The CLI arguments and config files.
  - Multiple Subject Alternative Names.
  - CA creation.
  - CRL creation, cert revoking.
  - Client and server cert types

What does not work:

  - Other types of certs (email, objsign, etc).
  - Signing CSR, creating CSRs.
  - Generating new certs off existing ones.

## Examples

Given a config file that looks like:

    [DEFAULT]
    SUBJECT_C=US
    SUBJECT_ST=Colorado
    SUBJECT_L=Denver
    SUBJECT_O=ExampleCorp
    SUBJECT_OU=
    SUBJECT_EMAIL=certs@example.com
    BITS=8192
    CA_KEY_FILE=ca.key
    CA_CERT_FILE=ca.crt
    CERT_FILE={{SUBJECT_CN}}.crt
    KEY_FILE={{SUBJECT_CN}}.key

    [dev]
    SUBJECT_OU=ExampleDevs
    VALID_DAYS=1095
    RUN_POST=yes
    POST_COMMAND=mail-to-dev

    [server]
    SUBJECT_OU=Webmaster
    RUN_POST=yes
    POST_COMMAND=deploy-to-server

Some example commands to create certificates:

    #  Show information about a cert
    rgca cert show cacert.pem
    #  Create a new CA
    rgca ca new example.com
    #  Create a dev cert for dev1.example.com
    rgca --config-group dev cert new dev1.example.com
    #  Create a dev cert with a san
    rgca --config-group dev cert new --san devtest.example.com dev2.example.com
    #  Create a dev cert with several sans, using "append domain" to reduce duplication
    rgca --config-group dev cert new --append-domain .example.com --san foo --san bar dev3
    #  Create a server cert (using the "server" group in the config file)
    rgca --config-group server cert new --san example.com www.example.com

## rgca --help

    Usage: rgca [OPTIONS] COMMAND [ARGS]...

      rgca is a Certificate Authority helper, to make creating certificates,
      either from scripts or from the CLI, easier.  All (reasonable) values can be
      passed either by CLI arguments, config files, or the environment.  See the
      help for the sub commands for more information, but an example use could be:

          rgca cert new www.example.com

      The above command is incomplete, as it doesn't specify various Subject items
      like Country, Locality, Organization, etc...  But if you run the above, it
      will tell you what is missing.  A more complete run might look like:

          rgca cert new --C US --ST Colorado --L Denver --O Example -E
          user@example.com www.example.com

      Or, if you specify subject items in a config file:

          rgca --config config.ini cert new www.example.com www.crt www.key

      It is compatible with OpenSSL commands (including managing the "serial" and
      "index.txt" files).

      One or more config files may be specified in "INI" format.  Earlier config
      files override values set in later files. There is a "DEFAULT" group that is
      always read, and other sections may be selected using the "--config-group"
      option, so that multiple configurations may be easliy switched between.

      Values may also be set using the environment.  Options that can be set from
      the environment are listed in the help related to those options.

      For example, take this "config.ini":

          [DEFAULT]     SUBJECT_C=US     SUBJECT_ST=Colorado     SUBJECT_L=Denver
          SUBJECT_O=Example     SUBJECT_OU=Corporate
          SUBJECT_EMAIL=admin@example.com

          [widget]     SUBJECT_OU=Widgets
          SUBJECT_EMAIL=admin@widgets.example.com

      Then you can run it with:

          rgca --config config.ini cert new www.example.com www.crt www.key
          rgca --config config.ini --config-group widget cert new
          widgets.example.com widgets.crt widgets.key

    Options:
      --config FILE                   Ini format config file  [env var: CONFIG;
                                      default: .rgca.ini,
                                      /home/sean/.config/rgca/config.ini]
      -G, --config-group, --group TEXT
                                      Additional group to pull settings from.  If
                                      set, named group in the config file will be
                                      loaded in addition to 'DEFAULT'.  [env var:
                                      CONFIG_GROUP; default: DEFAULT]
      --install-completion [bash|zsh|fish|powershell|pwsh]
                                      Install completion for the specified shell.
      --show-completion [bash|zsh|fish|powershell|pwsh]
                                      Show completion for the specified shell, to
                                      copy it or customize the installation.
      --help                          Show this message and exit.

    Commands:
      ca
      cert
      showkey  Display information about the key in a keyfile.

## rgca cert show --help

    Usage: rgca cert show [OPTIONS] CERT_FILE

      Display information about a certificate.

    Arguments:
      CERT_FILE  Certificate file to show information about.  [env var:
                 CERT_FILE;required]

    Options:
      --help  Show this message and exit.

## rgca ca new --help

    Usage: rgca ca new [OPTIONS] COMMON_NAME CA_KEY_FILE CA_CERT_FILE

    Arguments:
      COMMON_NAME   Main name on certificate  [env var: SUBJECT_CN;required]
      CA_KEY_FILE   File name to write private key to.  [env var:
                    CA_KEY_FILE;required]
      CA_CERT_FILE  File name to write CA certificate to.  [env var:
                    CA_CERT_FILE;required]

    Options:
      -b, --ca-key-bits, --bits INTEGER
                                      Size of generated key, in bits.  [env var:
                                      CA_KEY_BITS; default: 8192]
      -c, --cipher [des3|aes128|aes192|aes256]
                                      Cipher to use to encrypt CA key.  [env var:
                                      CA_CIPHER; default: Cipher.aes256]
      --passphrase TEXT               Passphrase for CA key  [env var:
                                      CA_PASSPHRASE]
      -P, --prompt-for-passphrase     Prompt for a passphrase, overriding the
                                      config or environment settings.
      -N, --no-passphrase             Do not put a passphrase on the key file.
      --overwrite / --no-overwrite    Overwrite the key file if it already exists.
                                      [default: no-overwrite]
      -d, --valid-days INTEGER        Number of days the certificate is valid for.
                                      [env var: VALID_DAYS; default: 365]
      -D, --digest [sha256|sha512]    Message digest to use when signing the key.
                                      [env var: DIGEST; default: sha512]
      -a, --append-domain TEXT        If provided, this value is appended to all
                                      domain names (CN, SAN) so short names can be
                                      used.  For example this creates
                                      ca.example.com rgca ca new --append-domain
                                      .example.com ca ca.crt ca.key  [env var:
                                      APPEND_DOMAIN]
      -C, --country-name, --C TEXT    Subject: Country name  [env var: SUBJECT_C;
                                      required]
      -ST, --state-name, --ST TEXT    Subject: State name  [env var: SUBJECT_ST;
                                      required]
      -L, --locality-name, --L TEXT   Subject: Locality(city) name  [env var:
                                      SUBJECT_L; required]
      -O, --organization-name, --O TEXT
                                      Subject: Organization name  [env var:
                                      SUBJECT_O; required]
      -OU, --organization-unit-name, --OU TEXT
                                      Subject: Organization unit name  [env var:
                                      SUBJECT_OU]
      -E, --email-address, --E TEXT   Subject: Email address  [env var:
                                      SUBJECT_EMAIL; required]
      --run-pre / --no-run-pre        Use '--pre-command' before certificate
                                      generation.  [env var: RUN_PRE; default: no-
                                      run-pre]
      --pre-command TEXT              Command to run to before starting
                                      certificate generation.  [env var:
                                      PRE_COMMAND]
      --run-post / --no-run-post      Use '--post-command' to post-process
                                      key/cert after generation.  [env var:
                                      RUN_POST; default: no-run-post]
      --post-command TEXT             Command to run to post-process cert/key
                                      after generation.  [env var: POST_COMMAND]
      --random-serial-bits [32|64|128]
                                      Number of bits for the random serial number
                                      generation.  [env var: RANDOM_SERIAL_BITS;
                                      default: 128]
      --help                          Show this message and exit.

## rgca cert new --help

    Usage: rgca cert new [OPTIONS] COMMON_NAME

      Create a new certificate signed by the CA key.

      This is compatible with the OpenSSL CA tools, and can read and write
      "serial" and "index.txt" files as used by OpenSSL.

      Various values for the certificate are given by the options marked with
      "Subject:". Options may be specified from the CLI, environment, or config
      file (in order of what overrides, with CLI overriding environment, then
      config).  See "rgca --help" for more information on the config file.

      If --run-pre is set, the command given to --pre-command is run before
      certificate generation is started.  If --run-post is set, the command given
      to --post-command is run after the certificate has been generated.  They are
      called with these environment variables set:

      SCRIPT_TYPE: The string "CERT_NEW".

      FILES: A space separated list of the files generated.

      CERT_FILE: The certificate file.

      KEY_FILE: The key file.

    Arguments:
      COMMON_NAME  Main name on certificate  [env var: SUBJECT_CN;required]

    Options:
      --cert-file TEXT                File name to write certificate to.  This
                                      name can be jinja2 templated from the
                                      environment.  [env var: CERT_FILE; default:
                                      {{ SUBJECT_CN }}.crt]
      --key-file TEXT                 File name to write private key to.  This
                                      name can be jinja2 templated from the
                                      environment.  [env var: KEY_FILE; default:
                                      {{ SUBJECT_CN }}.key]
      --serial-file PATH              File that has the next serial number in it.
                                      If undefined or a non-existant file, serial
                                      0 is used.  [env var: SERIAL_FILE]
      --random-serial / --no-random-serial
                                      Use a randomly generated serial number
                                      rather than the --serial-file.  [env var:
                                      RANDOM_SERIAL; default: random-serial]
      --random-serial-bits [32|64|128]
                                      Number of bits for the random serial number
                                      generation.  [env var: RANDOM_SERIAL_BITS;
                                      default: 128]
      --index-file PATH               File to write the certificate information to
                                      (ca database).  [env var: INDEX_FILE]
      -d, --valid-days INTEGER        Number of days the certificate is valid for.
                                      [env var: VALID_DAYS; default: 365]
      -s, --san TEXT                  Subject alternative name to add to the
                                      certificate.  The Common Name is listed as
                                      the first SAN.
      -b, --bits INTEGER              Size of generated key, in bits.  [env var:
                                      BITS; default: 8192]
      -D, --digest [sha256|sha512]    Message digest to use when signing the key.
                                      [env var: DIGEST; default: sha512]
      -a, --append-domain TEXT        If provided, this value is appended to all
                                      domain names (CN, SAN) so short names can be
                                      used.  For example this creates a
                                      web.example.com cert without having to
                                      repeat '.example.com' all over: rgca cert
                                      new --append-domain .example.com --san test
                                      --san foo web web.crt web.key  [env var:
                                      APPEND_DOMAIN]
      -C, --country-name, --C TEXT    Subject: Country name  [env var: SUBJECT_C;
                                      required]
      -ST, --state-name, --ST TEXT    Subject: State name  [env var: SUBJECT_ST;
                                      required]
      -L, --locality-name, --L TEXT   Subject: Locality(city) name  [env var:
                                      SUBJECT_L; required]
      -O, --organization-name, --O TEXT
                                      Subject: Organization name  [env var:
                                      SUBJECT_O; required]
      -OU, --organization-unit-name, --OU TEXT
                                      Subject: Organization unit name  [env var:
                                      SUBJECT_OU]
      -E, --email-address, --E TEXT   Subject: Email address  [env var:
                                      SUBJECT_EMAIL; required]
      -c, --cipher [des3|aes128|aes192|aes256]
                                      Cipher to use to encrypt certificate key.
                                      This is only used if a passphrase is
                                      specified.  [env var: CERT_CIPHER; default:
                                      Cipher.aes256]
      --ca-cert-file TEXT             File name of the CA certificate, if
                                      specified the generated cert is issued using
                                      this certificate.  This needs to be
                                      specified to properly be marked as being
                                      issued by the CA.  [env var: CA_CERT_FILE;
                                      required]
      --ca-key-file TEXT              File name of the CA key, if specified the
                                      generated cert is signed with this key.  If
                                      not specified, the cert is unsigned.  [env
                                      var: CA_KEY_FILE; required]
      --ca-passphrase TEXT            Passphrase to decrypt the key.  If not
                                      specified, and the key is encrypted, a
                                      passphrase will be prompted for.  [env var:
                                      CA_PASSPHRASE]
      -P, --prompt-for-passphrase     Prompt for a passphrase, overriding the
                                      config or environment settings.  Is
                                      overridden by --no-passphrase.
      -P, --passphrase TEXT           Passphrase to encrypt the key.  [env var:
                                      PASSPHRASE]
      -N, --no-passphrase             Do not put a passphrase on the key file.
                                      This overrides settings in the
                                      config/environment/CLI for
                                      --passphrase/--prompt-for-passphrase.  [env
                                      var: NO_PASSPHRASE]
      --run-pre / --no-run-pre        Use '--pre-command' before certificate
                                      generation.  [env var: RUN_PRE; default: no-
                                      run-pre]
      --pre-command TEXT              Command to run to before starting
                                      certificate generation.  [env var:
                                      PRE_COMMAND]
      --run-post / --no-run-post      Use '--post-command' to post-process
                                      key/cert after generation.  [env var:
                                      RUN_POST; default: no-run-post]
      --post-command TEXT             Command to run to post-process cert/key
                                      after generation.  [env var: POST_COMMAND]
      --cert-type [server]            Type of certificate to generate.  [env var:
                                      CERT_TYPE; default: server]
      --help                          Show this message and exit.

## License

CC0 1.0 Universal, see LICENSE file for more information.
