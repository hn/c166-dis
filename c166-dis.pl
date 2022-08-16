#!/usr/bin/perl
#
# c166-dis.pl, V0.2 ALPHA
#
# Disassembler for the c166 processor
#
# (C) 2000 Hajo Noerenberg
#
# http://www.noerenberg.de/
# https://github.com/hn/c166-dis
#
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3.0 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.
#

use FindBin qw($RealBin);
$fileIS="$RealBin/c166_is.txt";
$fileCC="$RealBin/c166_cc.txt";
$fileSFR="$RealBin/c166_sfr.txt";

###############################################################################
# Read opcodes

sub readcmd {
	open (CFILE,"<$fileIS") || die ("Opcode file not found !");
	while ($line = <CFILE>) {
		if ( $line =~ m/^\s*#/ ) {
#			print "Reading comment line : $line";
		} elsif ( $line =~ m/^(\w\w)\s+([24])\s+(\S+)\s+(.+)/ ) {
			$clength{hex($1)}=$2;
			$i=0; while ( defined($cpatt{hex($1)}[$i]) ) {
				$i++;
			}
			$cpatt{hex($1)}[$i]=$3;
			$cout{hex($1)}[$i]=$4;
#			print hex($1)." :: $1 : $2 : $3 : $4 \n";
		} elsif ( $line =~ m/^\s*$/ ) {
#			print "Reading empty line : $line";
		} else {
			die ("Error in opcode file : $line");
		}

	}
	close (CFILE);

	open (CFILE,"<$fileCC") || die ("Condition code file not found !");
	while ($line = <CFILE>) {
		if ( $line =~ m/^\s*#/ ) {
#			print "Reading comment line : $line";
		} elsif ( $line =~ m/^([01]{4})\s+(\S+)/ ) {
			$ccc{$1}=$2;
#			print "$1 : $2\n";
		} elsif ( $line =~ m/^\s*$/ ) {
#			print "Reading empty line : $line";
		} else {
			die ("Error in opcode file : $line");
		}

	}
	close (CFILE);

	open (CFILE,"<$fileSFR") || die ("Sfr code file not found !");
	while ($line = <CFILE>) {
		if ( $line =~ m/^\s*#/ ) {
#			print "Reading comment line : $line";
		} elsif ( $line =~ m/^([01]{8})\s+(\S+)/ ) {
			$csfr{$1}=$2;
#			print "$1 : $2\n";
		} elsif ( $line =~ m/^\s*$/ ) {
#			print "Reading empty line : $line";
		} else {
			die ("Error in opcode file : $line");
		}

	}
	close (CFILE);
}

###############################################################################
# Converter subs

# cRw(n)		wGPR: R0, R1, R2, ... R15
sub cRw {
	return "R".ord(pack("B*","0000".shift()));
}

# cRb(n)		bGPR: RL0, RH0, RL1, ... RH7
sub cRb {
	$tmp=shift();
	if ( substr($tmp,3,1) == "0" ) {
		$tmpo="RL";
	} else {
		$tmpo="RH";
	}
	return $tmpo.ord(pack("B*","00000".substr($tmp,0,3)));
}

# cregb(RR)              SFR/GPR byte context
sub cregb {
	$tmp=shift();
	if ( substr($tmp,0,4) == "1111" ) {
		return cRb(substr($tmp,4,4));
	} else {
		if ( defined($csfr{$tmp}) ) {
			return $csfr{$tmp};
		} else {
			return sprintf "0x%.2X",ord(pack("B*",$tmp));
		}
	}
}

# cregw(RR)              SFR/GPR word context
sub cregw {
	$tmp=shift();
	if ( substr($tmp,0,4) == "1111" ) {
		return cRw(substr($tmp,4,4));
	} else {
		if ( defined($csfr{$tmp}) ) {
			return $csfr{$tmp};
		} else {
			return sprintf "0x%.2X",ord(pack("B*",$tmp));
		}
	}
}

# cmem(MMMM)            1234H
sub cmem {
	$tmp=shift();
	$tmp=substr($tmp,8,8).substr($tmp,0,8);
	return sprintf "0x%s%s",map { sprintf "%.2X",ord($_) } split //, pack("B*",$tmp);
}

# cbitaddr(QQ,q)        -
sub cbitaddr {
	$ctmp=cregw(shift());
	return	$ctmp.".".ord(pack("B*","0000".shift()));
}

# cbitoff(QQ)
sub cbitoff {
	return	"(INCOMPLETE bitoff)";
}

# cirang2(:..##)
sub cirang2 {
	return "\#".ord(pack("B*","000000".shift()));
}

# cdata3(:.###)
sub cdata3 {
	return "\#".ord(pack("B*","00000".shift()));
}

# cdata4(#)
sub cdata4 {
	return "\#".ord(pack("B*","0000".shift()));
}

# cdata8(##)
sub cdata8 {
	return sprintf "\#0x%.2X",ord(pack("B*",shift()));
}

# cdata16(####)
sub cdata16 {
	$tmp=shift();
	$tmp=substr($tmp,8,8).substr($tmp,0,8);
	return sprintf "\#0x%s%s",map { sprintf "%.2X",ord($_) } split //, pack("B*",$tmp);
}

# cmask8(@@)
sub cmask8 {
	return	"(INCOMPLETE mask8)";
}

# ccaddr(MMMM)
sub ccaddr {
	$tmp=shift();
	$tmp=substr($tmp,8,8).substr($tmp,0,8);
	return sprintf "0x%s%s",map { sprintf "%.2X",ord($_) } split //, pack("B*",$tmp);
}

# cseg(SS)
sub cseg {
	return sprintf "0x%.2X",ord(pack("B*",shift()));
}

# crel(rr)
sub crel {
	$tmp=ord((pack("B*",shift())));
	if ( $tmp >= 128 ) {
		$tmp-=256;
	}
	return sprintf "0x%.8X",($ip+$fread+(2*$tmp));
#	return	"(INCOMPLETE $tmp rel : ".shift().")";
}

# ctrap7(
sub ctrap7 {
	return	"(INCOMPLETE trap7)";
}

# ccc(cc)               CC_UC, CC_NZ, ...
sub ccc {
	return	$ccc{shift()};
}

###############################################################################
# Main

print "#\n# c166-dis.pl disassembler for the c166 family\n#\n#\n";

readcmd;

open (IFILE,"<$ARGV[0]") || die ("Can not open input file");

if ( $ARGV[1] =~ m/(\w+)/ ) {
	seek(IFILE,hex($1),0);
	$ip=hex($1);	# instruction pointer IP
} else {
	$ip=0;		# instruction pointer IP
}

if ( $ARGV[2] =~ m/(\w+)/ ) {
	$maxip=$ip+hex($1);
} else {
	$maxip=$ip+256;
}

while ( $ip < $maxip ) {

	printf "%.8X  ",$ip;

	undef $inbuf; undef $comment;
	read (IFILE,$inbuf,2,0) || die ( "End of file (1)");
	$fread=2;
	$cmd=ord(substr($inbuf,0,1));
	if ( $clength{$cmd} == 4 ) {
		read (IFILE,$inbuf,2,2) || die ( "End of file (2)");
		$fread=4;
	}
	$obytes=sprintf "%s%s%s%s",map { sprintf "%.2X",ord($_) } split //, $inbuf;
	if (length($obytes) == 4) {
		print $obytes."      	";
	} else {
		print $obytes."  	";
	}

	$bits=unpack("B*",substr($inbuf,1,3));

	$i=0;
	while ( defined($cpatt{$cmd}[$i]) ) {
		if ( $bits =~ m/$cpatt{$cmd}[$i]/ ) {
			$A=$1;$B=$2;$C=$3;$D=$4;
			last;
		}
		$i++;
	}
	$ecout="print $cout{$cmd}[$i]";
	eval $ecout;

	$ip+=$fread;
	print "\n";
}

close (IFILE);

