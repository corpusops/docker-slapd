DISCLAIMER
============

**UNMAINTAINED/ABANDONED CODE / DO NOT USE**

Due to the new EU Cyber Resilience Act (as European Union), even if it was implied because there was no more activity, this repository is now explicitly declared unmaintained.

The content does not meet the new regulatory requirements and therefore cannot be deployed or distributed, especially in a European context.

This repository now remains online ONLY for public archiving, documentation and education purposes and we ask everyone to respect this.

As stated, the maintainers stopped development and therefore all support some time ago, and make this declaration on December 15, 2024.

We may also unpublish soon (as in the following monthes) any published ressources tied to the corpusops project (pypi, dockerhub, ansible-galaxy, the repositories).
So, please don't rely on it after March 15, 2025 and adapt whatever project which used this code.




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
- see [.env.dist](.env.dist) to start a configuration
- Those variables need to be encoded to base64 without newlines (a one line (`\n` removed)):
  - `SLAPD_SYNCREPL`: syncrepl configuration lines to add (bare slapd.conf configuration lines)
  - `SLAPD_ACLS`: acl configuration lines to add (bare slapd.conf configuration lines)

## test in dev
```bash
./create_ca_cert.sh
COMPOSE_FILE="docker-compose.yml:docker-compose-build.yml" docker-compose build
COMPOSE_FILE="docker-compose.yml:docker-compose-build.yml" docker-compose up
```
