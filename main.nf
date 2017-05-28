#!/usr/bin/env nextflow
/*

    nextflow script for running fasta through GFE pipeline 
    Copyright (c) 2014-2015 National Marrow Donor Program (NMDP)

    This library is free software; you can redistribute it and/or modify it
    under the terms of the GNU Lesser General Public License as published
    by the Free Software Foundation; either version 3 of the License, or (at
    your option) any later version.

    This library is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; with out even the implied warranty of MERCHANTABILITY or
    FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
    License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with this library;  if not, write to the Free Software Foundation,
    Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA.

    > http://www.gnu.org/licenses/lgpl.html

    ./nextflow run nmdp-bioinformatics/flow-GFE \
      -with-docker nmdpbioinformatics/flow-gfe \
      --fastafiles /location/of/fastafiles --outfile typing_results.txt

*/

params.fasta = "${baseDir}/tutorial"
params.output = "gfe_results.txt"
fastaglob = "${params.fasta}/*.fa.gz"
outputfile = file("${params.output}")
inputFasta = Channel.fromPath(fastaglob).ifEmpty { error "cannot find any reads matching ${fastaglob}" }.map { path -> tuple(sample(path), path) }
params.help = ''

/*  Help section (option --help in input)  */
if (params.help) {
    log.info ''
    log.info '---------------------------------------------------------------'
    log.info 'NEXTFLOW GFE'
    log.info '---------------------------------------------------------------'
    log.info ''
    log.info 'Usage: '
    log.info 'nextflow run main.nf -with-docker nmdpbioinformatics/flow-gfe --fasta fastafiles/ [--outfile gfe_results.txt]'
    log.info ''
    log.info 'Mandatory arguments:'
    log.info '    --fasta    FOLDER             Folder containing FASTA FILES'
    log.info 'Options:'
    log.info '    --outfile     STRING          Name of output file (default : gfe_results.txt)'
    log.info ''
    exit 1
}

/* Software information */
log.info ''
log.info '---------------------------------------------------------------'
log.info 'NEXTFLOW GFE'
log.info '---------------------------------------------------------------'
log.info "Input FASTA folder (--fastadir)        : ${params.fasta}"
log.info "Output file name   (--outfile)         : ${params.output}"
log.info "\n"


// Breaking up the fasta files
process breakupFasta{
  
  tag{ expected }

  input:
    file(expected) from inputFasta

  output:
    file('*.txt') into fastaFiles mode flatten

  """
    zcat ${expected} | breakup-fasta
  """
}

//Get GFE For each sequence
process getGFE{
  errorStrategy 'ignore'

  tag{ fastafile }

  input:
    file(fastafile) from fastaFiles

  output:
    file {"*.txt"}  into gfeResults mode flatten

  """
    cat ${fastafile} | fasta2gfe
  """
}

gfeResults
.collectFile() {  gfe ->
       [ "temp_file", gfe.text ]
   }
.subscribe { file -> copy(file) }

def copy (file) { 
  log.info "Copying ${file.name} into: $outputfile"
  file.copyTo(outputfile)
}

def sample(Path path) {
  def name = path.getFileName().toString()
  int start = Math.max(0, name.lastIndexOf('/'))
  return name.substring(start, name.indexOf("."))
}


