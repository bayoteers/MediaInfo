# -*- Mode: perl; indent-tabs-mode: nil -*-
#
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
#
# The Original Code is the Media Sniffer Bugzilla Extension.
#
# The Initial Developer of the Original Code is "Nokia Corporation"
# Portions created by the Initial Developer are Copyright (C) 2011 the
# Initial Developer. All Rights Reserved.
#
# Contributor(s):
#   Stephen Jayna <ext-stephen.jayna@nokia.com>

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
