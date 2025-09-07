#!/usr/bin/perl
use strict;
use File::Temp qw/ tempfile /;
use vars qw($CGI $CFG $STATUS $CMD $OBJCF);

my $configfile = shift;
$configfile = '/usr/share/nagios/nagiosmobile/include.inc.php'
    unless defined $configfile;
my $transurl = shift;
$transurl = '/usr/sbin/nagiosmobile_transurl' unless defined $transurl;

if (! -e $configfile || ! -e $transurl) {
    print "usage: $0 [.../include.inc.php] [.../nagiosmobile_transurl]\n";
    print "these files will be modified based on Nagios/pnp4nagios config\n";
    die "missing file(s) to edit";
}


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

system('rpm -q pnp4nagios >/dev/null');
my $pnp4nagios = ($? == 0) ? 1 : 0;

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
        } elsif (/^\$ACTION_HOST/ && $pnp4nagios) { 
            print $fh "\$ACTION_HOST = \"/pnp4nagios/index.php/mobile/graph/\%s/_HOST_\";\n";
        } elsif (/^\$ACTION_SERVICE/ && $pnp4nagios) { 
            print $fh "\$ACTION_SERVICE =  \"/pnp4nagios/index.php/mobile/graph/\%s/\%s\";\n";
        } elsif (/DO\s+NOT\s+MAKE\s+CHANGES\s+BELOW/i) {
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

#-----------------now edit the nagiosmobile_trans script------------------

open(TRANS_IN,"<$transurl")
    or die "unable to open $transurl for reading";

($fh,$filename) = tempfile("${transurl}_XXXXXX", UNLINK => 0);
die "unable to open tempfile" unless defined $fh;

$doedit = 1;

while (<TRANS_IN>) {

    if ($doedit) {
        if (/^\$STATUS_FILE/) {
            print $fh "\$STATUS_FILE = \"$STATUS\";\n";
        } elsif (/AUTO EDIT END/i) {
            $doedit = 0;

        } else {
            print $fh $_;
        }
    } else {
        print $fh $_;
    }
}

close(INC_IN);

rename($transurl,"$transurl.bak");
rename($filename,$transurl);
chmod 0755,$transurl;
