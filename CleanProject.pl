#!perl-w 

use strict;
use warnings;
use Cwd;
use File::Basename;
use File::Find;
use File::Path;

my @DirectoryNamesToPrune = (
    "bin"
  , "obj"
  , "temp"
);

my @FilePatternsToPrune = (
    ".+\\.log\$"
  , ".+\\.jww\$"
  , ".+\\.tmp\$"
);

my @IgnoreDirectoryMatchPatterns = (
    "^\.git\$"
  , "^\.svn\$"
);

# scoped for use of temp variables
my $RoughRegExPattern = "";
{
  my $addPipe = 0;
  foreach my $currDirectoryName (@DirectoryNamesToPrune)
  {
    if (0 < $addPipe)
    {
      $RoughRegExPattern .= "|";
    }
    $RoughRegExPattern .= "(";
    $RoughRegExPattern .= $currDirectoryName;
    $RoughRegExPattern .= ")";
    ++$addPipe;
  }
}

my $RegExForPrunableDirectoryName = "^(";
$RegExForPrunableDirectoryName .= $RoughRegExPattern;
$RegExForPrunableDirectoryName .= ")\$";

my @RootDirectories = @ARGV;
if (!@RootDirectories)
{
  $RootDirectories[0] = cwd();
}

my $numRootDirs = @RootDirectories;
print "\nSearching directory tree";
print "s" if (1 < $numRootDirs);
print ":\n";
for(my $i=0; $i < $numRootDirs; ++$i)
{
  $RootDirectories[$i] = Cwd::abs_path($RootDirectories[$i]);
  print "    $RootDirectories[$i]\n";
}
print "for directories which match the RegEx pattern:\n    $RegExForPrunableDirectoryName\n\n";

my @DirectoriesToPrume = ();
my @FilesToPrume = ();

find(\&IdentifyDirectoryPrunings, @RootDirectories);
my @SortedDirectories = sort {$b cmp $a} @DirectoriesToPrume;
foreach my $directory (@SortedDirectories)
{
  print "Pruning: $directory\n";
  rmtree $directory;
}

find(\&IdentifyFilePrunings, @RootDirectories);
my @SortedFilenames = sort @FilesToPrume;
foreach my $filename (@SortedFilenames)
{
  print "Deleting: $filename\n";
  unlink $filename;
}

sub IdentifyDirectoryPrunings()
{
  my $currentFile = $File::Find::name;
  my $DirName = $_;
  if (-d $currentFile)
  {
  # ignore this directory?
    foreach my $dirIgnorePattern (@IgnoreDirectoryMatchPatterns)
    {
      if ($DirName =~ /$dirIgnorePattern/i)
      {
        print "Ignoring the directory: $DirName\n";
        return;
      }
    }

    #print "walking: $currentFile\n";
    if ($DirName =~ /$RegExForPrunableDirectoryName/i)
    {
      push @DirectoriesToPrume, $currentFile;
    }
  }
}

sub IdentifyFilePrunings()
{
  my $currentFile = $File::Find::name;
  my $DirName = $_;
  
  # ignore this directory?
  if (-d $currentFile)
  {
    foreach my $dirIgnorePattern (@IgnoreDirectoryMatchPatterns)
    {
      if ($DirName =~ /$dirIgnorePattern/i)
      {
        print "Ignoring the directory: $DirName\n";
        return;
      }
    }
  }

  # Is this a file to be pruned/deleted/
  if (-f $currentFile)
  {
    foreach my $nameMatchPattern (@FilePatternsToPrune)
    {
      #print "Comparing: $currentFile to the match pattern: $nameMatchPattern\n";
      if ($currentFile =~ /$nameMatchPattern/i)
      {
        push @FilesToPrume, $currentFile;
      }
    }
  }
}

