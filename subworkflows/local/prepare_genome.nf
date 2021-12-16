/*
 * Prepare genome/transcriptome before alignment
 */

include { GET_CHROM_SIZES  } from '../../modules/local/get_chrom_sizes'
include { GTF2BED          } from '../../modules/local/gtf2bed'

workflow PREPARE_GENOME {
    take:
    ch_fastq

    main:
    // Get unique list of all fasta files
    ch_fastq
        .filter { it[2] }
        .map { it -> [ it[2], it[5].toString() ] }  // [ fasta, annotation_str ]
        .unique()
        .set { ch_fastq_sizes }

    /*
     * Make chromosome sizes file
     */
    GET_CHROM_SIZES ( ch_fastq_sizes )
    ch_chrom_sizes = GET_CHROM_SIZES.out.sizes
    samtools_version = GET_CHROM_SIZES.out.versions

    // Get unique list of all gtf files
    ch_fastq
        .filter { it[3] }
        .map { it -> [ it[3], it[5] ] }  // [ gtf, annotation_str ]
        .unique()
        .set { ch_fastq_gtf }

    /*
     * Convert GTF to BED12
     */
    GTF2BED ( ch_fastq_gtf )
    ch_gtf_bed = GTF2BED.out.gtf_bed
    gtf2bed_version = GTF2BED.out.versions

    ch_chrom_sizes
        .join(ch_gtf_bed, by: 1, remainder:true)
        .map { it -> [ it[1], it[2], it[0] ] }
        .cross(ch_fastq) { it -> it[-1] }
        .flatten()
        .collate(9)
        .map { it -> [ it[5], it[0], it[6], it[1], it[7], it[8] ]} // [ fasta, sizes, gtf, bed, is_transcripts, annotation_str ]
        .unique()
        .set { ch_fasta_index }

    emit:
    ch_fasta_index
    ch_gtf_bed
    samtools_version
    gtf2bed_version
}
