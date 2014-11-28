
package Import::Normalise;
use Moose;
use JSON;
use Env;
use FindBin qw($Bin);
use Hydstra;
use Try::Tiny;

#extends 'Import';

=head1 Import::Normalise

Normalise data

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Use this module to import configuration files

Code snippet.

  use Import::Normalise;
  
  my $normalise = Import::Normalise->new( 
   
  );

  
     
=cut

=head2 SUCCESS
  
  Constant used for logging the success status of the module at any step

=cut

 use constant SUCCESS => 1;
 
=head2 FAIL
  
  Constant used for logging the fail status of the module at any step

=cut

 use constant FAIL    => 0;
 
 has 'date' => ( is => 'ro', isa => 'Str'); 
 has 'latitude' => ( is => 'ro', isa => 'Str'); 
 has 'longitude' => ( is => 'ro', isa => 'Str'); 
 
=head1 EXPORTS

  * normalise()
  
=head1 SUBROUTINES/METHODS

=head2 normalise_latitude()
  
 Return the normalised latitude for HYDB.pm

=cut 

 sub normalise_latitude{
  my $self = shift;
  my $latitude = $self->latitude;
  
  if ( !defined $latitude || $latitude eq ''){
    return;
  }
  else{
    my ($integer, $decimal) = split(/\./,$latitude); 
    #return "int_dec lat [$integer]  [$decimal] [$latitude]";
    $decimal = substr($decimal, 0, 8);
    return $integer.'.'.$decimal;
    #return $latitude;
  }  
}

=head2 normalise_longitude()
  
 Return the normalised latitude for HYDB.pm

=cut 

 sub normalise_longitude{
  my $self = shift;
  my $longitude = $self->longitude;
  
  if ( !defined $longitude || $longitude eq ''){
    next;
  }
  else{
    my ($integer, $decimal) = split(/\./,$longitude); 
    #return "int_dec long [$integer]  [$decimal] [$longitude]";
    $decimal = substr($decimal, 0, 8);
    return $integer.'.'.$decimal;
    #return $longitude;
  }
}  
  
  
=head2 normalise_date()
  
 Return the normalised date for HYDB.pm

=cut 

 sub normalise_date{
  my $self = shift;
  my $date = $self->date;
  my $normalised_date = '';
  my $year  = '';
  my $month = '';
  my $day   = '';  

  #01/12/2013
  #yyyy                 /   mm    /   dd  
  if ( $date =~ m{([1-2]{1}[0-9]{1}\d{2})/??([0-1]{0,1}[0-9]{1})/??([0-3]{0,1}[0-9]{1})} ){
    $year  = $1;
    $month = $2;
    $day   = $3;
    #$normalised_date = $year.$month.$day."_yyyymmdd";
    $normalised_date = $year.$month.$day;
  }
  #dd                  /   mm    /   yyyy
  elsif ( $date =~ m{([0-3]{0,1}[0-9]{1})/??([0-1]{0,1}[0-9]{1})/??([1-2]{1}[0-9]{1}\d{2})} ){
    $day   = sprintf("%02d",$1);
    $month = sprintf("%02d",$2);
    $year  = sprintf("%4d",$3);
    #$normalised_date = $year.$month.$day."_ddmmyyyy";
    $normalised_date = $year.$month.$day;
  }               #yy                  /   mm    /   dd
=skip  
  elsif ( $date =~ m{(\d{2})/??([0-1]{0,1}[0-9]{1})/??([0-3]{0,1}[0-9]{1})} ){
    
    $year  = sprintf("%02d",$1);
    $month = sprintf("%02d",$2);
    $day   = $3;
    $year = 2000 + $year;
    #$normalised_date = $year.$month.$day." [$date] [$year] [$month] [$day] _yymmdd";
    $normalised_date = $year.$month.$day;
  }  
=cut  
  #dd                  /   mm    /   yy
  elsif ( $date =~ m{([0-3]{0,1}[0-9]{1})/??([0-1]{0,1}[0-9]{1})/??(\d{2})} ) {
    $day   = sprintf("%02d",$1);
    $month = sprintf("%02d",$2);;
    $year  = $3;
    
    $year = ( $year =~ m{^[0-3]{1}\d{1}} )? 2000+ $year : 1900  + $year;
    #$normalised_date = $year.$month.$day."_ddmmyy";
    $normalised_date = $year.$month.$day;
  }
  #return "\nDate [$date] normalised_date [$normalised_date] day [$day] month [$month] year [$year]";
  return $normalised_date;
  
=skip  
  elsif ( $date =~ m{[1-2]{1}[0,9]{1}\d{6}}
          m{(\d{1,2})/(\d{1,2})/(\d{2,4})} 
  ){
    
  }
  
  if ( $date !~ m{(\d{1,2})/(\d{1,2})/(\d{2,4})} ) {
    return 0;
  }
  
  
  $day   = sprintf( "%02d", $day );
  $month = sprintf( "%02d", $month );
  if ( $year =~ m{^\d\d$} ) {
    $year = '20' . $year;
  }
    
  $non_normalised_date
  
  my $nowdat = substr (NowString(),0,8); #YYYYMMDDHHIIEE to YYYYMMDD for default import date
  
    
    
    my $config_file = $self->config_dir.$self->db_file_name.'.json';
    print "importing table config file [$config_file]\n";
    
    my $json;
    {
      local $/; #Enable 'slurp' mode
      my $fh;
      try{
        open $fh, "<", lc($config_file) or die print "couldn't open config file [$config_file]\n";
        $json = <$fh>;
        close $fh;
        my $data = decode_json($json);
        return $data;
      }
      catch{
        print "issue opening [$_]\n";
        return 0;
      }

    };
=cut
      
 }

=head2 normalise_date()
  
 Return the normalised date for HYDB.pm

 



sub normalise_date{
  my $self = shift;
  my $date = $self->date;
  
  if ( $$dateref !~ m{(\d{1,2})/(\d{1,2})/(\d{2,4})} ) {
    $rejected++;
    return 0;
  }
  my $day   = $1;
  my $month = $2;
  my $year  = $3;
  $day   = sprintf( "%02d", $day );
  $month = sprintf( "%02d", $month );
  if ( $year =~ m{^\d\d$} ) {
    $year = '20' . $year;
  }
    
  $non_normalised_date
  
  my $nowdat = substr (NowString(),0,8); #YYYYMMDDHHIIEE to YYYYMMDD for default import date
  
  my $config_file = $self->config_dir.$self->db_file_name.'.json';
  print "importing table config file [$config_file]\n";
  
  my $json;
  {
    local $/; #Enable 'slurp' mode
    my $fh;
    try{
      open $fh, "<", lc($config_file) or die print "couldn't open config file [$config_file]\n";
      $json = <$fh>;
      close $fh;
      my $data = decode_json($json);
      return $data;
    }
    catch{
      print "issue opening [$_]\n";
      return 0;
    }

  };
}

=cut 
 
 no Moose;
 
 
=head1 AUTHOR

Sholto Maud, C<< <sholto.maud at gmail.com> >>

=head1 BUGS

Please report any bugs in the issues wiki.


=head1 SUPPORT

You can find documentation for this module on the Git repo

=over 4

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Sholto Maud.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Normalise

 