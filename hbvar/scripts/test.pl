use strict;
use Data::Dumper;

&usage if @ARGV<1;

#open IN,"" ||die "Can't open the file:$\n";
#open OUT,"" ||die "Can't open the file:$\n";

sub usage {
        my $usage = << "USAGE";
        Convert ensembl gtf file to UCSC refGene.txt file.
        Usage: $0 <ensembl gtf file> > <output file>
        Example:perl $0 genes_chr_novo.gtf > genes_chr_novo.refGene.bed
USAGE
print "$usage";
exit(1);
};

my $gtf_f = shift;

my $gtf = read_gtf($gtf_f);

foreach my $transid (keys %{$gtf}){
	# deal with exon information
	my @exon_sorted = sort {$a->[1] <=> $b->[1]} @{$gtf->{$transid}{'exon'}};

	# deal with cds information
	if(exists $gtf->{$transid}{'CDS'}){
		my @cds_sorted = sort {$a->[1] <=> $b->[1]} @{$gtf->{$transid}{'CDS'}};
	}
	
	# deal with stop and start codon informaton
	my ($thickStart,$thickEnd) = (0, 0);
	if(exists $gtf->{$transid}{'stop_codon'} && exists $gtf->{$transid}{'start_codon'}){
		my @arr = ($gtf->{$transid}{'stop_codon'}[1],$gtf->{$transid}{'stop_codon'}->[2],$gtf->{$transid}{'start_codon'}->[1],$gtf->{$transid}{'start_codon'}->[2]);
		my @arr_sorted = sort{$a <=> $b} @arr;
		$thickStart = $arr_sorted[0];
		$thickEnd = $arr_sorted[-1];
	}elsif(exists $gtf->{$transid}{'stop_codon'} && !(exists $gtf->{$transid}{'start_codon'})){
		$thickStart = $exon_sorted[0][1];
		$thickEnd = $gtf->{$transid}{'stop_codon'}[2];
	}elsif(!(exists $gtf->{$transid}{'stop_codon'}) && exists $gtf->{$transid}{'start_codon'}){
		$thickStart = $gtf->{$transid}{'start_codon'}[1];
		$thickEnd = $exon_sorted[-1][2];
	}else{
		$thickStart = $exon_sorted[-1][2];
		$thickEnd =  $exon_sorted[-1][2];
	}
	
	# deal with coding blocks
	my @exon_len;
	my @start_arr;
	my $s = $exon_sorted[0][1];
	foreach my $e (@exon_sorted){
		my $start = $e->[1] - $s;
		push @start_arr,$start;
		my $len = $e->[2] - $e->[1] + 1;
		push @exon_len,$len;
	}

	# print out the result
	my $exon_num = scalar(@exon_sorted);
	my $exon_len = join ",",@exon_len;
	my $start_arr = join ",",@start_arr;
	print "$exon_sorted[0][0]\t$exon_sorted[0][1]\t$exon_sorted[-1][2]\t$transid\t0\t$exon_sorted[0][3]\t$thickStart\t$thickEnd\t0\t$exon_num\t$exon_len,\t$start_arr,\n";
}

sub read_gtf{
	my ($f) = @_;
	my %gtf;
	open IN,"$f" || die $!;
	while(<IN>){
		chomp;
		my @t = split /\t/;
		my $transid = $1 if($t[8] =~ /transcript_id "([^"]+)";/);
		# store information in hash
		($t[3], $t[4]) = ($t[4], $t[3]) if($t[3] > $t[4]);
		if($t[2] =~ /exon/){
			push @{$gtf{$transid}{'exon'}},[$t[0], $t[3], $t[4], $t[6]];
		}
		if($t[2] =~ /CDS/){
			push @{$gtf{$transid}{'CDS'}},[$t[0], $t[3], $t[4], $t[6]];
		}
		if($t[2] =~ /start_codon/){
			$gtf{$transid}{'start_codon'} = [$t[0], $t[3], $t[4], $t[6]];
		}
		if($t[2] =~ /stop_codon/){
			$gtf{$transid}{'stop_codon'} = [$t[0], $t[3], $t[4], $t[6]];
		}
	}
	close IN;
	# return hash reference
	return \%gtf;
}