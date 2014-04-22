#!/usr/bin/perl -w
use Test::More tests=>2;
use Logger;
use FindBin qw($Bin);
use lib "$Bin/lib"; 
use Time::Local;
use Import;
use Import::Config;
use DBI;
use Data::Dumper;
use Hydstra;

use constant DB_DIR => 'C:/temp/gwdb'; 
use constant SQL_DIR => $Bin.'/tmp/'; 
use constant SQL_DB => 'gwdb.db'; 
use constant HY_DB => 'hydb.db'; 

  mkdir SQL_DIR  if (! -d SQL_DIR );
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
  my $localtime = sprintf("%04d%02d%02d%02d%02d%02d", $year+1900,$mon+1,$mday,$hour,$min, $sec);
  my $foreign_db = SQL_DIR.SQL_DB;
  my $hy_db = SQL_DIR.HY_DB;
  
  unlink ($hy_db);
=skip  
  my $dbh = DBI->connect(          
      "dbi:SQLite:dbname=$foreign_db", 
      "",                          
      "",                          
      { RaiseError => 1, AutoCommit => 0},         
  ) or die $DBI::errstr;


  ok(defined $dbh, 'DBI->connect() returned something' );
=cut   
  my $dbdir = DB_DIR;
  my @files = <$dbdir/*.txt>;

 
=skip  
  foreach my $GWDB_file (@files) {
    my @filename = split ('/',$GWDB_file);
    my ($filename,$fileext) = split (/\./,$filename[$#filename]);
    print "Files [$GWDB_file] name [$filename]\n";
    
    my $import = Import::Config->new(
        'config_dir'=>$Bin.'/config/',
        'db_file_name'=>uc($filename)
    );
    
    ok(defined $dbh, 'Import::Config->new() returned something' );
    
    my $config; 
    
    ok( $import->config, "JSON config file ok for [$filename]" );
  }
=cut  


  open my $fh, ">", 'c:/temp/log.txt';
  print $fh "Hello World\n";


  my $importer = Import->new(
        'config_dir'=>$Bin.'/config/',
        'import_dir'=>$dbdir 
  );
  
  my $tablesref = $importer->tables;
  
  ok(defined $tablesref, "importer->tables() ok");
  
  #@use $table for @{$tablesref};
  
   my $hydbh = DBI->connect(          
      "dbi:SQLite:dbname=$hy_db", 
      "",                          
      "",                          
      { RaiseError => 1, AutoCommit => 0},         
  ) or die $DBI::errstr;
    
    #my $t = 'Aquifer';
    
    #print $fh " table->create [$create]\n";
  
  ok(defined $hydbh, "connected to db/hydb.db ok");
    
  foreach ( @{$tablesref}){
    my $module = ucfirst($_);
    next if ($module eq 'Elevations' || $module eq 'Group' || $module eq 'Variable');
    #my $table = Hydstra::$module->new();
    #print $fh " table [$table]\n";
    my $hypm = "Hydstra::$module";
    my $table = $hypm->new();
    my $create = $table->create;
    my $prepare = $table->prepare;
    my @rw = split(',',$prepare);
    my @row;
    push (@row,'') for @rw;
    print $fh "module [$module]\n  create [$create]\n  prepare [$prepare]\n";
=sk  
    my $create = $table->create;
    print $fh "  create [$create]\n";
    
=cut  
    #ok(!defined $table->create, "table->create [$create] ok");
    $hydbh->do($create);
    #my $hysth = $hydbh->prepare($prepare);
    #$hysth->execute(@row);
  }  
  close ($fh);
    #$hydbh->do($table->create);

  $hydbh->commit;
  
  
  
  
  
  
#done_testing( $number_of_tests_run );
