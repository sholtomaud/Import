{
package Import::ToSQLite;
use Moose;
use JSON;
use DBI;
use Env;
use FindBin qw($Bin);
use Text::CSV_XS;
use Try::Tiny;
use Data::Dumper;
use Time::Local;

#H.A.S. Modules
use local::lib "$Bin/HAS/";
use Export::dbf;
use Hydstra;
use Import::fs;

extends 'Import';
__PACKAGE__->meta->error_class('Moose::Error::Croak');

=head1 Import::Tests

Tests data

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Use this module to import into an SQLite db

Code snippet.

  use Import::ToSQLite;
  
  my $sqlite = Import::ToSQLite->new( 
   
  );
     
=cut

 my $default_dir = $Bin;
 my $defaultdb_dir = $Bin.'\\db';
 my $defaulttemp = $Bin.'\\temp';
 my $junk = $defaultdb_dir.'\\temp.db';
 
 has 'config_dir' => ( is => 'ro', isa => 'Str', required => 1, default => $default_dir); 
 has 'tempdb_dir' => ( is => 'rw', isa => 'Str', required => 1, default => $defaultdb_dir); 
 has 'temp'       => ( is => 'rw', isa => 'Str', default => $defaulttemp); 
 has 'db_file'    => ( is => 'rw', isa => 'Str', required => 1,default => $junk); 
 

=head2 SUCCESS
  
  Constant used for logging the success status of the module at any step

=cut

 use constant SUCCESS => 1;
 
=head2 FAIL
  
  Constant used for logging the fail status of the module at any step

=cut

 use constant FAIL    => 0;
 
 has 'date' => ( is => 'ro', isa => 'DateTime'); 
 
=head1 EXPORTS

  * import()
  
=head1 SUBROUTINES/METHODS


=head2 import()

Import csv files to SQLite
  
  'temp'        =>$temp,
  'base_files'  =>\@base_files,
  'junk_db'     =>$junk_db
  
=cut


sub import_hydbutil_export_formatted_csv{
  my $self        = shift;
  my $db = $self->db_file;
  my $temp = $self->temp;
  my $base_files  = $_[0];
  my $fs = Import::fs->new();
  
  foreach my $file ( @{$base_files}){
    print "processing file [$file]\n";
    
    my $table = $fs->TableName($file);
  
    #catch any table errors before attempting to import
    if ( !defined ($table) || $table eq ''){
      next;
    }
    else{
      import_csv({table=>$table,file=>$file,db=>$db,temp=>$temp});
    }  
  }
  return 1;
}



=head2 import_csv()

Import data to SQLite

Use   
   import_csv({table=>$table,file=>$file,db=>$db});
  
=cut

sub import_csv{
  my $table = $_[0]->{table};
  my $file = $_[0]->{file};
  my $db = $_[0]->{db};
  my $temp = $_[0]->{temp};
  mkdir $temp if (! -d $temp );
  
  my $hydbh = DBI->connect(          
          "dbi:SQLite:dbname=$db", 
          "",                          
          "",                          
          { RaiseError => 1, AutoCommit => 0},         
      ) or die $DBI::errstr;
      
  my $module = ucfirst(lc($table)); 
  my $hytable = "Hydstra::$module";
  
  #my $varnum_column = "$hytable::$VARNUM";
  #print "varnum_column [$varnum_column]\n";
  
  my $hyt = $hytable->new();
  
  my $create = $hytable->create;
  my $prepare = $hytable->prepare;

  my @rw = split(',',$prepare);
  my @row;
  push (@row,'') for @rw;
  
  $hydbh->do($create);
  
  my $sth = $hydbh->prepare($prepare);
  
  my $csv = Text::CSV_XS->new ({ 
      sep_char => ',', 
      escape_char => '', 
      quote_char =>'', 
      allow_loose_quotes =>1 , 
      always_quote =>1 
  });
  
  open my $io, "<:encoding(utf8)", $file;
  my $count = 0;
  
#=skip    
  while (my $row = $csv->getline ($io)) {
    $count++;
   
    eval{
      $sth->execute(@{$row}); # or die $sth->errstr;
    };
    if ($@) {
      warn $@; # print the error
    }
    
    print "Importing table [$table] row [$count]    \r";
  }
#=cut    
  
  close $io;

  $hydbh->commit;

}
 
=head1 hash_import()

Import a hash refernce to a SQLite db

hash_import($hashref)

=cut 

 
sub import_hash{
  my $self        = shift;
  my $db = $self->db_file;
  my $temp = $self->temp;
  my $module = $_[0]->{module};
  my %data = %{$_[0]->{data}};

  my $hydbh = DBI->connect(          
        "dbi:SQLite:dbname=$db", 
        "",                          
        "",                          
        { RaiseError => 1, AutoCommit => 0},         
    ) or die $DBI::errstr;
    
  my $hytable = "Hydstra::".ucfirst(lc($module));
  my $hyt = $hytable->new();
  my $create = $hytable->create;
  my $prepare = $hytable->prepare;
  $hydbh->do($create);
  my $sth = $hydbh->prepare($prepare);
 
  my $base_system_file = "C:\\temp\\toSQLITE.txt";
  #unlink ( $base_system_file );
  open my $io, ">:encoding(utf8)", $base_system_file;
 
  my $count = 0;
  while ( my ($key, $row_value) = each %data ) {
    $count++;     
    eval{
      $sth->execute(@{$row_value}); 
    };
    if ($@) {
      warn $@; 
      print $io "execution warning [".Dumper(\@{$row_value})."]\n"; 
    }
  }
    
  close ($io);  
  $hydbh->commit;
  return 1;
} 
 
no Moose;
}  


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Sholto Maud.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

http://www.perlfoundation.org/artistic_license_2_0

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

1; # End of Tests
