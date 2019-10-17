# ansible+docker based slapd setup

## The /conf (/slapdconf inside container) dir
- `./conf` is a special directory where well name files are injected inside the slapd configuration upon container boot. All the files inside are processed with [frep](https://github.com/subchen/frep) to react, adapt, and replace some parameters inside with environement values
    - `./conf/slapd.conf` (default) is a special directory where well name files are injected inside the slapd configuration upon container boot
    - `./conf/schema/*` schema to use
    - `./conf/slapd.repl` syncrepl instruction for replication,<br/>
       the default template dumps `SLAPD_SYNCREPL` environment variable <br/>
       which should be a oneline BASE64 encoded string
    - `./conf/slapd.acls` ACLs to apply on DIT,<br/>
      the default template dumps `SLAPD_ACLS` environment variable<br/>
      which should be a oneline BASE64 encoded string
    - `./conf/slapd.d/*` (not finished)
- Those variables need to be encoded to base64 without newlines (a one line (`\n` removed)):
  - `SLAPD_SYNCREPL`
  - `SLAPD_ACLS`

## After init
* Run this kind of ldif to apply syncrepl

