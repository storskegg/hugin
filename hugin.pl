#!/usr/bin/perl
use strict;
use warnings;
use feature q{say};

use Data::Dumper;
use Sys::Load qw/getload uptime/;
use Net::AWS::SES;
use feature q{say};

my $status   = qx{git -C "/rd" status};
my $modified = qx{stat -l `find /rd -type f -mtime -1 -print | grep -v '.git'`};

#I stole this from somewhere...stackoverflow, I presume.
sub sec_to_dhms_sensible2 {
  require integer;
  local $_ = shift;
  my ($d, $h, $m, $s);
  $s = $_ % 60; $_ /= 60;
  $m = $_ % 60; $_ /= 60;
  $h = $_ % 24; $_ /= 24;
  $d = $_;

  return ($d, $h, $m, $s);
}

my ($one, $five, $fifteen) = getload();
my ($d, $h, $m, $s) = sec_to_dhms_sensible2(int uptime());

my $uptime = "Uptime: " . $d . "d " . $h . "h " . $m . "m " . $s . "s";
my $load   = "Load: " . $one . " " . $five . " " . $fifteen;

my $template = qq{
TOP SNAPSHOT:
$uptime
$load

GIT STATUS:
$status

MODIFIED FILES (LAST 24h):
$modified
};

my $ses = Net::AWS::SES->new(
  access_key => 'ACCESS_KEY',
  secret_key => 'SECRET_KEY',
);

my $r = $ses->send(
  From    => 'From@someone.com',
  To      => 'To@someone.com',
  Subject => 'Branch Report MSN',
  Body    => $template,
);

unless ($r->is_success) {
  die "could not deliver the message.";
}

say $template;

