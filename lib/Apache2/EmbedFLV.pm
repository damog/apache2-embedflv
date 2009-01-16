=head1 NAME

Apache2::EmbedFLV - Embed FLV videos into a templated web interface
using Flowplayer

=head1 SYNOPSIS

On your Apache configuration file:

 <Files ~ "\.flv$">
   SetHandler modperl
	 PerlResponseHandler Apache2::EmbedFLV
 </Files>

This is needed in order to have Flowplayer work out of the box:

 <Location /flowplayer.swf>
   SetHandler modperl
	 PerlResponseHandler Apache2::EmbedFLV::FlowPlayer
 </Location>
 <Location /flowplayer.controls.swf>
   SetHandler modperl
	 PerlResponseHandler Apache2::EmbedFLV::FlowPlayer::Controls
 </Location>

That's it. Just go to any FLV video within your web server.

=head1 DESCRIPTION

C<Apache2::EmbedFLV> enables Apache to show FLV videos using Flowplayer
and a (yet-to-be) customizable template. This will ease any deployment
of FLV video galleries you'd need to do since you could just put the
FLVs on an Apache accessible location, and they will be presented on a
proper way to your final user.

=head1 SEE IT IN ACTION

You can see it in action here: L<http://dev.axiombox.com/apache2-flowplayer>.

=head1 BEHIND THE SCENES

C<Apache2::EmbedFLV> is a hack. The most prominent hack within the
distribution is the embedded Flowplayer. You don't need to separately
download and install it as it is already served using
C<Apache2::EmbedFLV::FlowPlayer>, with an up-to-date base64 encoded
string. This is possible due to: a) ease installation and deployment
using standard CPAN installation methods, and b) Flowplayer being a nice
GPL product.

=head1 CUSTOMIZATION

As of 0.1 release, customization of the template is not possible, but
it shouldn't take that long before this is possible. If you are brave
though, you can edit lib/Apache/EmbedFLV/Template.pm directly.

=head1 PARTICIPATE

Code is hosted at L<http://github.com/damog/apache2-embedflv>.

=head1 AUTHOR

David Moreno <david@axiombox.com>.

=head1 THANKS

Nabbr.com, L<http://nabbr.com/>, and Flowplayer L<http://flowplayer.com/>.

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

			# TODO: this should use user's template
			my $t = Apache2::EmbedFLV::Template->new;
			$r->print($t->process(uri => $r->uri, md5 => $md5));

			return Apache2::Const::OK;
		}
	}
}

1;

__END__
Hello! Your md5 cookie is [% md5 %]

