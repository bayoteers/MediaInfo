# -*- Mode: perl; indent-tabs-mode: nil -*-

package Bugzilla::Extension::MediaInfo;

use strict;
use base qw(Bugzilla::Extension);

use Bugzilla::Comment;

use File::Copy qw/ copy /;
use File::Temp qw/ tempfile /;
use POSIX;

our $VERSION = '0.01';

sub attachment_process_data {
    my ($self, $args) = @_;

    return unless $args->{attributes}->{mimetype} =~ m/^video/;

    my $data = ${ $args->{data} };
    my (undef, $tempfile) = tempfile();

    if (ref $data) {
        # $data is a filehandle.
        copy($data, $tempfile) || die($!);
    }
    else {
        # $data is a blob.
        open(OUTPUT, ">$tempfile") || die($!);
        print OUTPUT $data;
        close OUTPUT;
    }

    my $comment;

    if (-e "/usr/bin/mediainfo") {
        $comment = `/usr/bin/mediainfo $tempfile`;
    }
    elsif (-e "/usr/bin/gst-discoverer-0.10") {
        $comment = `/usr/bin/gst-discoverer-0.10 --timeout=60 $tempfile`;
    }
    elsif (-e "/usr/bin/file") {
        $comment = `/usr/bin/file -b $tempfile`;
    }

    if ($comment) {
        my $bug = $args->{attributes}->{bug};
        $bug->add_comment("Attachment info: " . $comment);
    }

    unlink($tempfile) || die($!);
}

__PACKAGE__->NAME;
