
# ==========================================
# LABORATORY ACTIVITY:
# MOLECULAR MECHANISMS OF MUSCLE CONTRACTILITY
# Gene: ATP2A2
# ==========================================

# Load required packages
library(rentrez)
library(ggplot2)

# Assignment information
gene_symbol <- "ATP2A2"
transcript_accession <- "NM_170665.4"
clinvar_id <- "17799"
variant_protein <- "p.Pro602Leu"

# Create required folders
for (x in c("data", "results", "figures")) {
  dir.create(x, showWarnings = FALSE)
}

# Display assignment details
cat("Gene:", gene_symbol, "\n")
cat("Transcript:", transcript_accession, "\n")
cat("ClinVar ID:", clinvar_id, "\n")
cat("Protein variant:", variant_protein, "\n")


# ==========================================
# STEP 3: RETRIEVE NCBI GENE RECORD
# ==========================================

# Search for ATP2A2 in the human NCBI Gene database
hits <- entrez_search(
  db = "gene",
  term = paste0(
    gene_symbol,
    "[Gene Name] AND txid9606[Organism]"
  ),
  retmax = 20
)

# Check if gene was found
if (length(hits$ids) == 0) {
  stop("Gene not found")
}

# Verify the exact gene symbol
gene_id <- NA_character_

for (id in hits$ids) {
  rec <- entrez_summary(db = "gene", id = id)
  
  if (toupper(rec$name) == toupper(gene_symbol)) {
    gene_id <- id
    gene_info <- rec
    break
  }
}

if (is.na(gene_id)) {
  stop("Exact human gene not found")
}

# Display retrieved information
cat("Gene Symbol:", gene_info$name, "\n")
cat("NCBI Gene ID:", gene_id, "\n")
cat("Official Name:", gene_info$description, "\n")
cat("Chromosome:", gene_info$chromosome, "\n")

# Save the gene summary
writeLines(
  c(
    paste("Gene symbol:", gene_info$name),
    paste("NCBI Gene ID:", gene_id),
    paste("Official name:", gene_info$description),
    paste("Chromosome:", gene_info$chromosome)
  ),
  "results/gene_summary.txt"
)

cat("\nGene summary successfully saved!\n")


# ==========================================
# STEP 4: RETRIEVE MATCHING PROTEIN SEQUENCE
# ==========================================

# Retrieve the GenBank record of the assigned transcript
gb <- entrez_fetch(
  db = "nuccore",
  id = transcript_accession,
  rettype = "gb",
  retmode = "text"
)

# Extract the matching RefSeq protein accession
pat <- '/protein_id="NP_[0-9]+[.][0-9]+"'

fragment <- regmatches(
  gb,
  regexpr(pat, gb)
)

if (length(fragment) == 0 || fragment == "") {
  stop("NP protein ID not found. Inspect transcript record.")
}

protein_accession <- gsub(
  '^/protein_id="|"$',
  '',
  fragment
)

# Verify the protein accession
cat("Matched protein:", protein_accession, "\n")

# Retrieve protein FASTA sequence
protein_fasta <- entrez_fetch(
  db = "protein",
  id = protein_accession,
  rettype = "fasta",
  retmode = "text"
)

# Check FASTA validity
if (!startsWith(protein_fasta, ">")) {
  stop("Invalid FASTA sequence")
}

# Save protein FASTA
fasta_file <- file.path(
  "data",
  paste0(gene_symbol, "_protein.fasta")
)

writeLines(protein_fasta, fasta_file)

# Save protein accession
writeLines(
  paste("NP accession:", protein_accession),
  "results/protein_accession.txt"
)

cat("Protein FASTA successfully saved!\n")
cat("FASTA file:", fasta_file, "\n")


# ==========================================
# STEP 5: PROTEIN LENGTH AND AMINO ACID
# COMPOSITION ANALYSIS
# ==========================================

# Read the saved protein FASTA file
fasta_lines <- readLines(fasta_file)

# Extract the protein sequence
sequence <- paste(
  fasta_lines[!grepl("^>", fasta_lines)],
  collapse = ""
)

# Clean and standardize the sequence
sequence <- toupper(gsub("\\s+", "", sequence))

# Split sequence into individual amino acids
aa <- strsplit(sequence, "")[[1]]

# Calculate total protein length
protein_length <- length(aa)

cat("================================\n")
cat("ATP2A2 PROTEIN ANALYSIS\n")
cat("================================\n")

cat("Protein accession:", protein_accession, "\n")
cat("Protein length:", protein_length, "amino acids\n")

# Define the 20 standard amino acids
standard <- strsplit(
  "ACDEFGHIKLMNPQRSTVWY",
  ""
)[[1]]

# Count the frequency of each amino acid
counts <- table(
  factor(aa, levels = standard)
)

# Create amino acid frequency table
results <- data.frame(
  AminoAcid = standard,
  Count = as.integer(counts)
)

# Save frequency table as CSV
write.csv(
  results,
  "results/amino_acid_composition.csv",
  row.names = FALSE
)

# Identify the three most abundant amino acids
top_three <- results[
  order(-results$Count),
][1:3, ]

cat("\nThree most abundant amino acids:\n")
print(top_three)

# Check for any non-standard amino acid symbols
nonstandard <- sum(!aa %in% standard)

cat("\nNon-standard residues:", nonstandard, "\n")

# Create amino acid composition bar graph
fig1 <- ggplot(
  results,
  aes(x = AminoAcid, y = Count)
) +
  geom_col(fill = "grey45") +
  theme_bw() +
  labs(
    title = "ATP2A2 Amino Acid Composition",
    x = "Amino Acid",
    y = "Number of Residues"
  )

# Display graph
print(fig1)

# Save graph as PNG
ggsave(
  "figures/01_amino_acid_composition.png",
  fig1,
  width = 8,
  height = 5,
  dpi = 300
)

cat("\nAmino acid analysis completed!\n")
cat("CSV and graph successfully saved!\n")


# ==========================================
# STEP 6: CLINVAR VARIANT INVESTIGATION
# ==========================================

# Assigned variant information
variant_name <- paste0(
  "NM_170665.4(ATP2A2):c.1805C>T"
)

protein_change <- "p.Pro602Leu"

variant_type <- "Single nucleotide variant (missense)"

condition <- "Acrokeratosis verruciformis of Hopf"

classification <- "Pathogenic"

review_status <- paste(
  "Criteria provided, multiple submitters,",
  "no conflicts"
)

# Record ClinVar findings
clinvar_summary <- c(
  "CLINVAR VARIANT ANALYSIS",
  "========================",
  paste("Gene:", gene_symbol),
  paste("NCBI Gene ID:", gene_id),
  paste("ClinVar Variation ID:", clinvar_id),
  paste("Variant:", variant_name),
  paste("Protein change:", protein_change),
  paste("Transcript:", transcript_accession),
  paste("Variant type:", variant_type),
  paste("Associated condition:", condition),
  paste("Aggregate classification:", classification),
  paste("Review status:", review_status),
  "Total submissions: 3",
  "Submissions contributing to aggregate: 2",
  "Latest evaluation: June 9, 2023",
  "Most recent submission: February 23, 2026",
  "Date accessed: November 14, 2026",
  paste(
    "NCBI ClinVar:",
    "https://www.ncbi.nlm.nih.gov/clinvar/variation/17799/"
  )
)

# Save ClinVar summary
writeLines(
  clinvar_summary,
  "results/clinvar_summary.txt"
)

cat("ClinVar summary successfully saved!\n")


# ==========================================
# STEP 7: PROTEIN-POSITION VISUALIZATION
# ==========================================

# Extract the amino-acid position from the variant
matched <- regmatches(
  variant_protein,
  regexpr("[0-9]+", variant_protein)
)

position <- as.integer(matched)

# Verify the position against the reference protein
if (is.na(position) || position < 1 ||
    position > protein_length) {
  stop("Variant position is outside the reference protein length")
}

cat("Reference protein length:", protein_length, "\n")
cat("Variant position:", position, "\n")
cat("Protein change:", variant_protein, "\n")

# Create linear protein-position plot
fig2 <- ggplot() +
  
  # Draw the reference protein
  geom_segment(
    aes(
      x = 1,
      xend = protein_length,
      y = 0,
      yend = 0
    ),
    linewidth = 2
  ) +
  
  # Mark the variant position
  geom_point(
    aes(x = position, y = 0),
    color = "red",
    size = 4
  ) +
  
  # Label the mutation
  annotate(
    "text",
    x = position,
    y = 0.25,
    label = variant_protein,
    size = 4
  ) +
  
  xlim(0, protein_length) +
  ylim(-0.6, 0.6) +
  theme_void() +
  
  labs(
    title = "ATP2A2 Reference Protein",
    subtitle = paste(
      "Variant position:",
      position,
      "| Protein length:",
      protein_length,
      "amino acids"
    ),
    x = "Amino-acid position"
  ) +
  
  theme(
    axis.title.x = element_text()
  )

# Display plot
print(fig2)

# Save second figure
ggsave(
  "figures/02_variant_position.png",
  fig2,
  width = 8,
  height = 2.5,
  dpi = 300
)

cat("Protein-position figure successfully saved!\n")
