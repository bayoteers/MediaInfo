# -*- Mode: perl; indent-tabs-mode: nil -*-


package Bugzilla::Extension::MediaInfo;

#use strict;
use base qw(Bugzilla::Extension);
use Bugzilla::Comment;
use POSIX;
use File::Copy cp;

our $VERSION = '0.01';


sub attachment_process_data {
    my ($self, $args) = @_;
    return unless $args->{attributes}->{mimetype} =~ m/^video/;
   
    my $data = ${$args->{data}};
    # $data is a filehandle.
    if (ref $data) {
        cp($data, "/tmp/bug_attachment");
    }
    # $data is a blob.
    else {
        open OUTPUT, ">/tmp/bug_attachment";
        print OUTPUT $data;
        close OUTPUT;
    }

    my $comment = "";
    if (-e "/usr/bin/mediainfo")
    {
        $comment = `/usr/bin/mediainfo /tmp/bug_attachment`;
    }
    elsif (-e "/usr/bin/gst-discoverer-0.10")
    {
        $comment = `/usr/bin/gst-discoverer-0.10 --timeout=60 /tmp/bug_attachment`;
    }
    elsif (-e "/usr/bin/file")
    {
        $comment = `/usr/bin/file -b /tmp/bug_attachment`;
    }
    else {
        # Return without printing additional comment
        return;
    }
    my $bug = $args->{attributes}->{bug};
    $bug->add_comment("Attachment info: " . $comment);
    unlink '/tmp/bug_attachment';
  
}

 __PACKAGE__->NAME;
