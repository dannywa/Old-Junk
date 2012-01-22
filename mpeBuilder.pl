#!/usr/bin/perl -w
#
# Create a WME profile to build a set of WMA large files
# from a set of MP3s (AudioBook)
#
use strict;
our $VERSION = q/mpeBuilder 0.7/;

use Getopt::Std;
my %opts;
getopts('nv', \%opts);

# Location of WMCmd batch script
my $WMCmd = q|"C:\\Program Files\\Windows Media Components\\Encoder\\WMCmd.vbs"|;

# Regex to extract Chapter and Part information from existing files
#my $regex = qr|Chapter ([0-9]+) - (.+)\s+\(([0-9]+).+\.mp3|;
#my $regex = qr|C([0-9]+)P([0-9]+) (.+)\.mp3|;
my $regex = qr|Chapter ([0-9]+)([A-M]) - (.+)\.mp3|;
#my $regex = qr|D([0-9][0-9] [0-9])([0-9])\.mp3|;

#
# Structure of the hash:
# {  <Chapter #>  =>  [  <Chapter Name>,  { <Chapter Part #> => <filename> }  ]
my %CH;

#while (<>) {
foreach (glob "*.mp3") {
#	my ($chnum, $chname, $chpart) = m/$regex/;
	my ($chnum, $chpart, $chname) = m/$regex/;
#	$chnum =~ s/ //;
#	$chname = $chnum;
	next unless $chname;
	chomp;
	$chnum   =  $chnum + 0;
	$chpart  =  ord($chpart) + 0;
	if (exists $CH{$chnum}) {
		$CH{$chnum}[1]{$chpart} = $_;
	} else {
		$CH{$chnum} = [ $chname, { $chpart => $_ } ];
	}
#	print join("\t", $chnum, $chname, $chpart), "\n";
}


#  $i              Chapter #
#  $j              Chapter part #
#  $CH{$i}[0]      Chapter name
#  $CH{$i}[1]{$j}  Filename
foreach my $i (sort {$a <=> $b} keys(%CH)) {
	my $wmeFile =  $opts{n} ? q|/dev/null| : sprintf("CH%02d.wme", $i);
	my $newChapter = sprintf("CH%02d %s.wma", $i, $CH{$i}[0]);
	my @parms;
	my $Another = q(
            RolloverType="-1"
            RolloverSourceGroup="WMENC_SOURCEGROUP_AUTOROLLOVER_TO_NEXT");

	open my $FH, ">$wmeFile"   or   die "Can't open $wmeFile";

	&pHeader($FH);

	print 'rem ', $newChapter, "\n"  if $opts{n} or $opts{v};

	foreach my $j (sort {$a <=> $b} keys(%{$CH{$i}[1]})) {
		&pFile( @parms )   if scalar @parms;
		@parms = ( $FH, $j, $CH{$i}[1]{$j}, $Another );
		print "rem     ", $CH{$i}[1]{$j}, "\n"   if $opts{n} or $opts{v};
	}
	if ( scalar @parms ) {
		$parms[$#parms] = "";
		&pFile( @parms );
	}
	&pTarget( $FH, $newChapter );

	&pFooter($FH);

	close $FH;
	printf "cscript.exe %s -wme %s\n", $WMCmd, $wmeFile;
}


exit 0;

sub pHeader {
	my $FH = shift;
	print $FH <<pHeader
<?xml version="1.0"?>

<WMEncoder major_version="9"
    minor_version="0"
    Name="WMEncoder15403"
    SynchroniesOperation="0" >
    <Description />
    <SourceGroups >

pHeader
}

sub pFile {
	my ($FH, $fileOrdinal, $sourceFile, $continue) = @_;
	print  $FH  <<pSource
        <SourceGroup Name="Source $fileOrdinal" $continue >
            <Source Type="WMENC_AUDIO"
                Scheme="file"
                InputSource="$sourceFile" > 
                <UserData >
                </UserData>

            </Source>

            <EncoderProfile id="Voice quality audio (CBR)" />
            <UserData >
            </UserData>

        </SourceGroup>

pSource
}

sub pTarget {
	my ($FH, $targetFile) = @_;
	print $FH  <<pTarget
    </SourceGroups>

    <File LocalFileName="$targetFile" />
pTarget
}

sub pFooter {
	my $FH = shift;
	print $FH <<pFooter
    <WMEncoder_Profile id="Voice quality audio (CBR)" >
    <![CDATA[        <profile version="589824" 
             storageformat="1" 
             name="Voice quality audio (CBR)" 
             description=""> 
                   <streamconfig majortype="{73647561-0000-0010-8000-00AA00389B71}" 
                   streamnumber="1" 
                   streamname="Audio Stream" 
                   inputname="Audio409" 
                   bitrate="32024" 
                   bufferwindow="-1" 
                   reliabletransport="0" 
                   decodercomplexity="" 
                   rfc1766langid="en-us" 
 > 
             <wmmediatype subtype="{00000161-0000-0010-8000-00AA00389B71}"  
                   bfixedsizesamples="1" 
                   btemporalcompression="0" 
                   lsamplesize="1487"> 
           <waveformatex wFormatTag="353" 
                         nChannels="2" 
                         nSamplesPerSec="22050" 
                         nAvgBytesPerSec="4003" 
                         nBlockAlign="1487" 
                         wBitsPerSample="16" 
                         codecdata="0044000017003D170000"/> 
            </wmmediatype>
            </streamconfig>
    </profile> 
    ]]>
    </WMEncoder_Profile>

    <UserData >
        <WMENC_LONG Name="Encoding\\Dest" Value="5" />
        <WMENC_STRING Name="Encoding\\Audio0" Value="{0A2A3D83-A7C6-4704-AF3D-B531B1F6A816}" />

        <WMENC_STRING Name="Encoding\\Video0" />
        <WMENC_STRING Name="Encoding\\Script0" />
        <WMENC_LONG Name="Encoding\\Type" Value="0" />
        <WMENC_LONG Name="Encoding\\Bitrate0\\Video0\\CustomW" Value="-1" />
        <WMENC_LONG Name="Encoding\\Bitrate0\\Video0\\CustomH" Value="-1" />

    </UserData>

</WMEncoder>
pFooter
}


