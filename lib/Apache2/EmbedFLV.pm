=head1 NAME

Apache2::EmbedFLV - Embed FLV videos into a templated web interface
using Flowplayer.

=head1 SYNOPSIS

On your Apache configuration file:

 <Files ~ "\.flv$">
   SetHandler modperl
   PerlResponseHandler Apache2::EmbedFLV
 </Files>

If you want to restrict only a certain directory to serve FLVs using
C<Apache2::EmbedFLV>, you can wrap the C<Files> declaration on a
C<Directory> block. For more information, take a look at excellent
Apache2's documentation.

Flowplayer is shipped with this module. This is done to ease
deployment. You only have to add this to the httpd config:

 <Location /flowplayer.swf>
   SetHandler modperl
   PerlResponseHandler Apache2::EmbedFLV::FlowPlayer
 </Location>
 <Location /flowplayer.controls.swf>
   SetHandler modperl
   PerlResponseHandler Apache2::EmbedFLV::FlowPlayer::Controls
 </Location>

That's it. Just go to any FLV video within your web server. With that
setup, C<Apache2::EmbedFLV> will use a default template.

=head1 ADVANCED POKING

Take a look at the default template located at example/template.tt.
That is not the real file used by this module but it's a verbatim copy.
The file is placed there just as an example so you can make
your own template without too much internal poking.

Once you have your own template, just C<PerlSetVar> it to the handler:

 <Files "\.flv$">
   SetHandler modperl
   PerlSetVar template /path/to/my/template.tt
   PerlResponseHandler Apache2::EmbedFLV
 </Files>

Flowplayer is shipped with this distribution. See FLOWPLAYER VERSION
for versioning details. Within the module, Flowplayer is base64-encoded
in C<Apache2::EmbedFLV::FlowPlayer> and in C<Apache2::EmbedFLV::FlowPlayer::Controls>.
This allows great ease of deployment and installation on just minimal
overhead increase. There would be a number of reasons why you wouldn't
want this, so this module allows you to override that default behaviour.
Just C<PerlSetVar flowplayer>:

 <Files "\.flv$">
   SetHandler modperl
   PerlSetVar template /path/to/my/template.tt
   # you would have to have http://yourserver.com/somewhere/flowplayer.swf:
   PerlSetVar flowplayer /somewhere/flowplayer.swf
   # or...
   PerlSetVar flowplayer http://my.other.server/rocks/flowplayer.swf
   PerlResponseHandler Apache2::EmbedFLV
</Files>

I believe it's pretty obvious that the templating system used and
required is L<Template::Toolkit>. Wherever you want to embed the video
within, just call: C<[% video %]>.

=head1 DESCRIPTION

C<Apache2::EmbledFLV> has been already described on the previous section
:-)

However...

C<Apache2::EmbedFLV> enables Apache to show FLV videos using Flowplayer. 
This will ease any deployment of FLV video galleries you'd need to do
since you could just put the FLVs on an Apache accessible location, and
they will be presented on a proper way to your final user.

=head1 SEE IT IN ACTION

You can see it in action here: L<http://axiombox.com/apache2-embedflv/video>.

=head1 BEHIND THE SCENES

C<Apache2::EmbedFLV> is a hack. The most prominent hack within the
distribution is the embedded Flowplayer as already explained above. 
You don't need to separately
download and install it as it is already served using
C<Apache2::EmbedFLV::FlowPlayer>, with an up-to-date base64 encoded
string. This is possible due to: a) ease installation and deployment
using standard CPAN installation methods, and b) Flowplayer being a nice
GPL product.

=head1 FLOWPLAYER VERSION

Flowplayer 3.0.3 is the one shipped with C<Apache2::EmbedFLV> 0.1.
Refer to L<http://flowplayer.org> for details.

=head1 PROJECT

You can always see the latest information on this project on:
L<http://axiombox.com/apache2-embedflv>.

Code is hosted at L<http://github.com/damog/apache2-embedflv>.

=head1 AUTHOR

David Moreno <david@axiombox.com>, L<http://damog.net/>.
Some other similar projects are announced on the Infinite Pig
Theorem blog: L<http://log.damog.net>.

=head1 THANKS

=over

=item * Bill Cromie, who allowed me to use my employer's resources to
have some fun with this little project.

=item * Flowplayer L<http://flowplayer.com/>.

=item * Raquel Hernándex, L<http://maggit.net>, who made the default template.

=back

=head1 COPYRIGHT

Copyright (C) 2009 by David Moreno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Flowplayer, also shipped with this distribution, is GPL:
L<http://flowplayer.org/download/LICENSE_GPL.txt>.

=cut

package Apache2::EmbedFLV;

our $VERSION = '0.1';

use Apache2::Request;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();
use Apache2::Util ();
use Apache2::Const -compile => qw/OK :common DIR_MAGIC_TYPE/;
use Apache2::EmbedFLV::Template;
use Data::Dumper;
use Cwd;
use Digest::MD5 qw/md5_hex/;

sub handler {
	my($r) = shift;

	if(! -e $r->filename) {
		return Apache2::Const::NOT_FOUND;
	} elsif(! -r $r->filename) {
		return Apache2::Const::FORBIDDEN;
	} else {
		my $req = Apache2::Request->new($r);

		if(
				# let's face it, this is why Perl sucks
				$req->param and
				scalar keys %{$req->param} == 1 and
				not $req->param( ${ [ keys %{$param} ] }[0] ) and
				length ${ [ keys %{$req->param} ] }[0] == 32
		) {
			my($md5) = keys %{$req->param}; # not too intuitive
			if($md5 eq md5_hex($r->filename)) {
				$r->content_type("video/x-flv");
				open my $fh, "<", $r->filename or die "Apache2::EmbedFLV wrong $!!";
				while(<$fh>) {
					$r->print($_);
				}
				close $fh;
				return Apache2::Const::OK;
			} else {
				return Apache2::Const::FORBIDDEN;
			}
		} else {
			my $md5 = md5_hex($r->filename);
			$r->content_type("text/html");

			my $template = $r->dir_config('template');
			my $flowplayer = $r->dir_config("flowplayer");

			my $t = Apache2::EmbedFLV::Template->new($template);
			$r->print(
				$t->process(
					uri => $r->uri,
					md5 => $md5,
					flowplayer => $flowplayer,
					template => $template
				)
			);

			return Apache2::Const::OK;
		}
	}
}

1;

__END__
Hello! Your md5 cookie is [% md5 %]

