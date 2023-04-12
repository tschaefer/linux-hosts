# hostsctl

> :warning: **This project is not active anymore, therefore the repository is archived.**
> Please use the ruby implementation https://github.com/tschaefer/ruby-hosts/ :warning:

**hostsctl** - Query and control the system hosts file.

## Introduction

**hostsctl** may be used to query and change the system hosts file entries.

* list entries
* add new entry
* remove entry
* set hostname of existing entry
* add and remove alias of existing entry

## Installation

    $ perl Makefile.PL
    $ make dist
    $ VERSION=$(perl -Ilib -le 'require "./lib/Linux/Hosts.pm"; print $Linux::Hosts::VERSION;')
    $ cpanm Linux-Hosts-$VERSION.tar.gz

## Usage

For usage of command line tool `hostsctl` see following help output.

    Usage:
        hostsctl --help|-h | --man|-m | --version|-v

        hostsctl [--no-legend] [--no-pager] list

        hostsctl add ADRESS HOSTNAME [ALIASES] | remove ADDRESS

        hostsctl set-hostname ADDRESS HOSTNAME

        hostsctl add-alias ALIASES | remove-alias ALIASES

    Options:
      base:
        --help|-h
                Print short usage help.

        --man|-m
                Print extended usage help.

        --version|-v
                Print version string.

      list:
        --no-legend
                Do not print a legend (column headers and hints).

        --no-pager
                Do not pipe output into a pager.

    Parameters:
        list    List all hosts entries tabular formatted with info about number
                of entries.

        add ADDRESS HOSTNAME [ALIASES]
                Add new hosts entry for given ADDRESS and HOSTNAME. Add optional
                comma seperated ALIASES.

        remove ADDRESS
                Remove hosts entry by ADDRESS.

        set-hostname ADDRESS HOSTNAME
                Set canonical hostname of hosts entry by ADDRESS.

        add-alias ADDRESS ALIASES
                Add comma seperated ALIASES from hosts entry by ADDRESS,

        remove-alias ADDRESS ALIASES
                Remove comma seperated ALIASES from hosts entry by ADDRESS,

For API documentation use [perlgib](https://github.com/tschaefer/perl-gib).

## License

[The "Artistic License"](http://dev.perl.org/licenses/artistic.html).

## Is it any good?

[Yes](https://news.ycombinator.com/item?id=3067434)
