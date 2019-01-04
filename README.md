# Postfwd

Postfwd is written in perl to combine complex postfix restrictions in a ruleset similar to those of the most firewalls. The program uses the postfix policy delegation protocol to control access to the mail system before a message has been accepted (please visit http://www.postfix.org/SMTPD_POLICY_README.html for more information). It allows you to choose an action (e.g. reject, dunno) for a combination of several smtp parameters (like sender and recipient address, size or the client's TLS fingerprint).

Important: [Documentation](https://postfwd.org/doc.html), [Quickstart guide](https://postfwd.org/quick.html) and [Examples](https://postfwd.org/example-cfg.txt) are located at official postfwd web page [postfwd.org](https://postfwd.org/).

If you are interested in postfwd, please subscribe to [mailing list](http://listi.jpberlin.de/mailman/listinfo/postfwd-users).

## Installation

### Distribution packages

Popular Linux distributions like `Debian` and `Ubuntu` have `postfwd 1.35` included in their package repository, so only thing you need to do is run `apt-get install postfwd`.

After that you can run or stop postfwd using systemd, init or script `/etc/init.d/postfwd`.

To change default arguments with which postfwd is run, edit file `/etc/default/postfwd`.

### Manual installation

Clone this repository and copy `postfwd2` from directory `./sbin` to your PATH environment (eg. /usr/sbin/).

There are several perl module dependencies needed to run postfwd. These are mentioned at [postfwd home page](https://postfwd.org/). For `postfwd2` it is:

* Net::Server::Daemonize
* Net::Server::Multiplex
* Net::Server::PreFork
* Net::DNS
* IO::Multiplex

You can install them using `cpan`.

```bash
perl -MCPAN -e shell
install Net::Server::Daemonize \
        Net::Server::Multiplex \
        Net::Server::PreFork \
        Net::DNS \
        IO::Multiplex
```

Note: Before installing with `cpan` make sure that you have installed `gcc`, `gcc-devel` and `make` or `build-essential` to build perl modules.

### Docker

Postfwd can be run in a docker container. Please see [postfwd.org/docker](https://postfwd.org/docker) for more information.

## Configuration

By default postfwd listens on port 10040 and configuration file is located in `/etc/postfix/postfwd.cf`, but this can be overriden with postfwd arguments. To show postfwd argument list, simply run `postfwd2 --help`.

### Postfwd with Postfix

Simple `postfix` setup to use `postfwd` can be configured using following options. After you change the configuration, you need to reload postfix:

```INI
127.0.0.1:10040_time_limit   = 3600
smtpd_recipient_restrictions = permit_mynetworks
                               reject_unauth_destination
                               check_policy_service inet:127.0.0.1:10040
```

Note: If you do not run postfwd on same server where postfix is run, replace IP address `127.0.0.1` to IP address where your postfwd instance is located.

For more instructions to setup postfwd with postfix refer to [Postfwd Integration](https://postfwd.org/doc.html#integration).

### Rules file

Sample postfwd configuration file can be found in file `./etc/postfwd.cf.sample` located in this repository.

To make your own rule set, refer to documentation and examples.

### Checking the ruleset

To check if your ruleset has correct syntax, use command `postfwd -f <PATH-TO-CONFIG> -C`.

## Running postfwd manually

To run postfwd in `daemon` mode as user `postfwd` and group `postfwd` using configuration file `/etc/postfix/postfwd.cf`, use this command:

```bash
postfwd --daemon -f /etc/postfwd.cf -u postfwd -g postfwd
```

## Plugins

Postfwd functionality can be extended by creating plugins. Sample plugin can be found in `plugins/postfwd.plugins.sample` in this repository.

If you are interested in plugin development, use [plugin development documentation](https://postfwd.org/doc.html#plugins) as reference.

List of public plugins:

* Geographical based anti-spam plugin: https://github.com/Vnet-as/postfwd-anti-geoip-spam-plugin
