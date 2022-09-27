#!/usr/bin/perl
use strict;
use File::Temp qw/ tempfile /;
use vars qw($CGI $CFG $STATUS $CMD $OBJCF);

my $configfile = shift;
die "need include.inc.php on command line" unless defined($configfile) &&
    -e $configfile;

open(RPM,"rpm -q nagios -l|")
    or die "unable to open rpm -q nagios for file list";
while(<RPM>) {
    chomp;
    if (/cgi\.cfg$/) {
        $CGI = $_;
    } elsif (/nagios\.cfg$/) {
        $CFG = $_;
    }
}
close(RPM);

system('rpm -q pnp4nagios 2>/dev/null');
my $pnp4nagios = ($! == 0);


open(CFG,"<$CFG")
    or die "unable to open $CFG for reading";

while(<CFG>) {
    chomp;
    s/#.*$//;
    if (/^\s*status_file\s*=\s*(.*)$/) {
        $STATUS = $1;
    } elsif (/^\s*command_file\s*=\s*(.*)$/) {
        $CMD = $1;
    } elsif (/^\s*object_cache_file\s*=\s*(.*)$/) {
        $OBJCF = $1;
    }
}
close(CFG);

if (!defined($STATUS) || !defined($CMD) || !defined($OBJCF)
    || !defined($CGI)) {
    die "missing some necessary pointers to files";
}


open(INC_IN, "<$configfile")
    or die "unable to open $configfile for reading";

my ($fh,$filename) = tempfile("${configfile}_XXXXXX", UNLINK => 0);
die "unable to open tempfile" unless defined $fh;

my $doedit = 1;

while (<INC_IN>) {

    if ($doedit) {
        if (/^\$STATUS_FILE/) {
            print $fh "\$STATUS_FILE = \"$STATUS\";\n";
        } elsif (/^\$COMMAND_FILE/) {
            print $fh "\$COMMAND_FILE = \"$CMD\";\n";
        } elsif (/^\$CGI_FILE/) {
            print $fh "\$CGI_FILE = \"$CGI\";\n";
        } elsif (/^\$OBJECTS_FILE/) {
            print $fh "\$OBJECTS_FILE = \"$OBJCF\";\n";
        } elsif (/^ACTION_HOST/ && $pnp4nagios) { 
            print $fh "\$ACTION_HOST = \"/pnp4nagios/index.php/mobile/graph/\%s/__HOST__\"\n";
        } elsif (/^ACTION_SERVICE/ && $pnp4nagios) { 
            print $fh "\$ACTION_SERVICE =  \"/pnp4nagios/index.php/mobile/graph/\%s/\%s\"\n";
        } elsif (/^DO\s+NOT\s+MAKE\s+CHANGES\s+BELOW/i) {
            $doedit = 0;

        } else {
            print $fh $_;
        }
    } else {
        print $fh $_;
    }
}

close(INC_IN);

rename($configfile,"$configfile.bak");
rename($filename,$configfile);
chmod 0666,$configfile;

