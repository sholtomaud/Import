#!/usr/bin/perl -w
use FindBin qw($Bin);
use JSON;
use DBI;
use JSON;
use Text::CSV_XS;
use local::lib "$Bin";
use Import;
use Data::Dumper;
use Time::Local;
use Hydstra;

use constant DB_DIR => 'C:/temp/gwdb'; 
use constant SQL_DIR => 'C:/temp/gwdb/sqlite/'; 
use constant SQL_DB => 'gwdb.db'; 
use constant HY_DB => 'hydb.db'; 

  mkdir SQL_DIR  if (! -d SQL_DIR );
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
  my $localtime = sprintf("%04d%02d%02d%02d%02d%02d", $year+1900,$mon+1,$mday,$hour,$min, $sec);
  my $foreign_db = SQL_DIR.SQL_DB;
  
  my $dbh = DBI->connect(          
      "dbi:SQLite:dbname=$foreign_db", 
      "",                          
      "",                          
      { RaiseError => 1, AutoCommit => 0},         
  ) or die $DBI::errstr;

  my $dbdir = DB_DIR;
  my @files = <$dbdir/*.txt>;

  
  #if there is a fundamental error then only do a partial import (don't import to Hydstra)
  #if $partial_import = 1 it will be a partial import
  my $partial_import = 0;

=skip    
  foreach my $GWDB_file (@files) {
    my @filename = split ('/',$GWDB_file);
    my ($filename,$fileext) = split (/\./,$filename[$#filename]);
    print "Files [$GWDB_file] name [$filename]\n";
    
    my $import = Import::Config->new(
        'config_dir'=>$Bin.'/lib/config/',
        'db_file_name'=>uc($filename)
    ); 
    
  }  
    foreach my $GWDB_file (@files) {
    my @filename = split ('/',$GWDB_file);
    my ($filename,$fileext) = split (/\./,$filename[$#filename]);
    print "Files [$GWDB_file] name [$filename]\n";
    
    my $import = Import::Config->new(
        'config_dir'=>$Bin.'/lib/config/',
        'db_file_name'=>uc($filename)
    );
    
    my $config; 
    
    if (! $import->config ){
      #log those files that do not have any json configuration
      #$logger->"partial import because [$table] doesn't have json config file"; #log that it is a partial import and why
      $partial_import = 1;
      next;
    }
    else{ 
      $config = $import->config;
    }
    
    my $foreign_table_name = $config->{foreign_table_name};
    my $foreign_table_sqlprepare = $config->{foreign_table_sqlprepare};
    
    my $foreign_table_sqlprepare = $config->{foreign_table_sqlcreate};
    
    my $foreign_fields = $config->{elements};
    print "foreign_table_name [$foreign_table_name]\n";
    #print "Fields [".$_->{foreign_field}."]\n" for @{$config->{elements}};
    #print "return [".Dumper($fields)."]\n";
    
    print "creating tables";
    $dbh->do($config->{foreign_table_sqlcreate});
    my $sth = $dbh->prepare($config->{foreign_table_sqlprepare});
    
    
    #Setup Text::CSV_XS 
    my $csv = Text::CSV_XS->new ({ 
        sep_char => '|', 
        escape_char => '', 
        quote_char =>'', 
        allow_loose_quotes =>1 , 
        always_quote =>1 
    });
    
    #Open .txt file 
    open my $io, "<:encoding(utf8)", $GWDB_file or die "$GWDB_file : $!";
    my $count =0;
 
=skip    
    foreach $column_no ( 0..$#data_line ){
      my $sth = $dbh->prepare($sql_table->prepare);
    }


    while (my $row = $csv->getline ($io)) {
      $count++;
      #get rid of annoying unmatched quotes etc.
      #actually these might be to indicate that the record is contained in multiple lines.
      map(s{["'\\]}{}g, @{$row});
      ($count == 1) ? next :  $sth->execute(@{$row}) or die $sth->errstr;

      #my @data_line = @{$row};

      #INSERT INTO SITE (SITE, LATITUDE, LONGITUDE) SELECT (RN, LATITUDE, LONGITUDE ) FROM REGISRATIONS; 
      #INSERT INTO GWHOLE (SITE, DATE, STATUS) SELECT (RN, RDATE, STATUS ) FROM REGISRATIONS; 

      #$table->foreign_field;
      #match  
      #foreach $row in 

      print "  - Processing row [$count]           \r"; 
    }
    #$sth->finish();
    close ($io);
  }
  $dbh->commit;
=cut  
  #$dbh->disconnect();  
  
  my $importer = Import->new(
        'config_dir'=>$Bin.'/lib/config/',
        'import_dir'=>$dbdir 
  );
  
  my $tablesref = $importer->tables;
  print "Tables [".Dumper($tablesref)."]\n";
  
  #my $href = $dbh->selectall_hashref( q/SELECT ID, Player, Sport FROM Players_Sport/, q/ID/ );
  
  #print "Dumper hashref [".Dumper($href)."]\n";
  
=skip  
  my $row = $dbh->selectall_arrayref();
  
  #my $href = $dbh->selectall_hashref( q/SELECT ID, Player, Sport FROM Players_Sport/, q/ID/ );
  
  
  #qq(SELECT Elevation_data.RN as 'station', Elevation_data.ELEVATION as 'elev', Elevation_data.PIPE as 'pipe', Elevation_data.PRECISION as 'elevacc', ELEVATION_DATA.MEAS_POINT as 'meas_point' 
  
  #$foreach create tables.
  
  my ($hydbh,$hysth);
    
  my $import = Import->new(
     'config_dir'=>$Bin.'/lib/config/',
  );
    
  print "tables [".Dumper($import->tables)."]\n";
  
  foreach ( $import->tables ){
    $hydbh->do($_->create);
    $hysth->prepare($_->create);
  }
  
  $hysth
  
  #foreach table in the db
    #for each column in the table
      #find out what table and field the colum maps to in hydstra
      
      
      
      Hydstra{$table}{$field}
      
      
   #   foreach row push data into the appropriate table and field.
    
  

  
  my $tables = $import->tables;
  
  
  mkdir SQL_DIR  if (! -d SQL_DIR );
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
  my $localtime = sprintf("%04d%02d%02d%02d%02d%02d", $year+1900,$mon+1,$mday,$hour,$min, $sec);
  my $hy_db = SQL_DIR.$localtime.'_'.HY_DB;
  
  my $hydbh = DBI->connect(          
      "dbi:SQLite:dbname=$hy_db", 
      "",                          
      "",                          
      { RaiseError => 1, AutoCommit => 0},         
  ) or die $DBI::errstr;

  my $dbdir = DB_DIR;
  my @files = <$dbdir/*.txt>;
=cut  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
1;