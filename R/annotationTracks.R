createAnnotationTrack_event <- function(eventGr, type){
  
  if(type == "A3SS") {
    event_track <- createAnnotationTrackA3SS_event(eventGr)
  }
  
  if(type == "A5SS") {
    event_track <- createAnnotationTrackA5SS_event(eventGr)
  }
  
  if (type == "SE"){
    event_track <- createAnnotationTrackSE_event(eventGr)
  }
  
  if (type == "RI"){
    event_track <- createAnnotationTrackRI_event(eventGr)
  }
  
  if (type == "MXE"){
    event_track <- createAnnotationTrackMXE_event(eventGr)
  }
  
  return(event_track)
  
}

createAnnotationTrack_transcripts <- function(eventGr, gtf_exons, 
                                              type, is_strict){
  
  if(type == "A3SS") {
    txn_tracks <- createAnnotationTrackA3SS_transcripts(eventGr, gtf_exons)
  }
  
  if(type == "A5SS") {
    txn_tracks <- createAnnotationTrackA5SS_transcripts(eventGr, gtf_exons)
  }
  
  if (type == "SE"){
    txn_tracks <- createAnnotationTrackSE_transcripts(eventGr, gtf_exons,
                                                      is_strict)
  }
  
  if (type == "RI"){
    txn_tracks <- createAnnotationTrackRI_transcripts(eventGr, gtf_exons,
                                                      is_strict)
  }
  
  if (type == "MXE"){
    txn_tracks <- createAnnotationTrackMXE_transcripts(eventGr, gtf_exons,
                                                      is_strict)
  }
  
  return(txn_tracks)
  
}


createAnnotationTrackSE_transcripts <- function(eventGr, gtf_exons,
                                                is_strict){
  
  # Transcripts overlapping with splicing event 
  ovl.e1 <- GenomicRanges::findOverlaps(eventGr$exon_upstream, 
                                        gtf_exons, type = "any")
  ovl.e2 <- GenomicRanges::findOverlaps(eventGr$exon_target, 
                                        gtf_exons, type = "any")
  ovl.e3 <- GenomicRanges::findOverlaps(eventGr$exon_downstream, 
                                        gtf_exons, type = "any")
  
  mytx.ids.e1 <- gtf_exons$transcript_id[subjectHits(ovl.e1)]
  mytx.ids.e2 <- gtf_exons$transcript_id[subjectHits(ovl.e2)]
  mytx.ids.e3 <- gtf_exons$transcript_id[subjectHits(ovl.e3)]
  
  #obtain intron range for inclusion event and skipping event
  intron.skipping <- GenomicRanges::GRanges(seqnames = seqnames(eventGr$exon_target),
                                            ranges = IRanges(
                                              start = end(eventGr$exon_upstream) + 1,  
                                              end = start(eventGr$exon_downstream) - 1),
                                            strand = strand(eventGr$exon_target)
  )
  
  intron.inclusion <- GenomicRanges::GRanges(seqnames = seqnames(eventGr$exon_target),
                                             ranges = IRanges(
                                               start = c(end(eventGr$exon_upstream) + 1,
                                                         end(eventGr$exon_target) + 1),  
                                               end = c(start(eventGr$exon_target) - 1,
                                                       start(eventGr$exon_downstream) -1)
                                             ),
                                             strand = strand(eventGr$exon_target)
  )
  
  #find transcripts with exons overlapping intronic regions
  ovl.intron.inclusion <- GenomicRanges::findOverlaps(intron.inclusion, 
                                                      gtf_exons, type = "any")
  mytx.ids.intron.inclusion <- gtf_exons$transcript_id[subjectHits(ovl.intron.inclusion)]
  
  ovl.intron.skipping <- GenomicRanges::findOverlaps(intron.skipping, 
                                                     gtf_exons, type = "any")
  mytx.ids.intron.skipping <- gtf_exons$transcript_id[subjectHits(ovl.intron.skipping)]
  
  #decide wich transcripts to plot in inclusion and skipping tracks
  if (is_strict){
    mytx.ids.3exons <- intersect(mytx.ids.e1, mytx.ids.e3) #has both flaking exons
    mytx.ids.3exons <- intersect(mytx.ids.3exons, mytx.ids.e2) #and the target exon
    mytx.ids.2exons <- intersect(mytx.ids.e1, mytx.ids.e3)
    
  }else {
    mytx.ids.3exons <- union(mytx.ids.e1, mytx.ids.e3) #has either flaking exons
    mytx.ids.3exons <- intersect(mytx.ids.3exons, mytx.ids.e2) #and the target exon  
    mytx.ids.2exons <- union(mytx.ids.e1, mytx.ids.e3)
  }
  
  mytx.ids.3exons <- setdiff(mytx.ids.3exons, mytx.ids.intron.inclusion)
  #mytx.ids.2exons <- setdiff(mytx.ids.2exons, mytx.ids.3exons)
  mytx.ids.2exons <- setdiff(mytx.ids.2exons, mytx.ids.intron.skipping)
  
  # Inclusion track
  # Recover exons of transcripts for the inclusion track using transcript IDs
  # AnnotationDbi::keytypes(gtf_txdb)
  res <- dplyr::filter(as.data.frame(gtf_exons), transcript_id %in% mytx.ids.3exons)
  
  # Create data frame for inclusion track - follow the model from data(geneModels)
  res.df <- res[, c("seqnames", "start", "end", "strand", "exon_id", "transcript_name")]
  colnames(res.df) <- c("chromosome","start","end","strand","exon","transcript")
  
  if (nrow(res.df) > 0){ 
    res.df$feature <- "Inclusion"
    inclusionTrack <- Gviz::GeneRegionTrack(range = res.df, name = "Inclusion", 
                                            transcriptAnnotation = "transcript")  
  }else {
    inclusionTrack <- Gviz::GeneRegionTrack(range = GRanges(), name = "Inclusion", 
                                            transcriptAnnotation = "transcript")  
  }
  
  # Skipping track
  # Recover exons of transcripts for the skipping track using transcript IDs
  res <- dplyr::filter(as.data.frame(gtf_exons), 
                       transcript_id %in% mytx.ids.2exons)
  
  # Create data frame for inclusion track - follow the model from data(geneModels)
  res.df <- res[, c("seqnames", "start", "end", "strand", "exon_id", "transcript_name")]
  colnames(res.df) <- c("chromosome","start","end","strand","exon","transcript")
  
  if (nrow(res.df) > 0){
    res.df$feature <- "Skipping"
    skippingTrack <- Gviz::GeneRegionTrack(range = res.df, name = "Skipping", 
                                           transcriptAnnotation = "transcript")  
  }else {
    skippingTrack <- Gviz::GeneRegionTrack(range = GRanges(), name = "Skipping", 
                                           transcriptAnnotation = "transcript")  
  }
  
  txn_tracks <- list("inclusionTrack" = inclusionTrack,
                     "skippingTrack" = skippingTrack)
  return(txn_tracks)
  
}

createAnnotationTrackRI_transcripts <- function(eventGr, gtf_exons,
                                                is_strict){
  
  # Transcripts overlapping with splicing event 
  ovl.e1 <- GenomicRanges::findOverlaps(eventGr$exon_upstream, 
                                        gtf_exons, type = "any")
  ovl.e2 <- GenomicRanges::findOverlaps(eventGr$exon_ir, 
                                        gtf_exons, type = "equal")
  ovl.e3 <- GenomicRanges::findOverlaps(eventGr$exon_downstream, 
                                        gtf_exons, type = "any")
  
  mytx.ids.e1 <- gtf_exons$transcript_id[subjectHits(ovl.e1)]
  mytx.ids.e2 <- gtf_exons$transcript_id[subjectHits(ovl.e2)]
  mytx.ids.e3 <- gtf_exons$transcript_id[subjectHits(ovl.e3)]
  
  #obtain intron range from the retention event
  intron <- GenomicRanges::GRanges(seqnames = seqnames(eventGr$exon_ir),
                                   ranges = IRanges(
                                     start = end(eventGr$exon_upstream) + 1,  
                                     end = start(eventGr$exon_downstream) - 1),
                                   strand = strand(eventGr$exon_ir)
  )
  
  #find transcripts with exons overlapping intronic regions
  ovl.intron <- GenomicRanges::findOverlaps(intron, gtf_exons, type = "any")
  mytx.ids.intron <- gtf_exons$transcript_id[subjectHits(ovl.intron)]
  
  #decide wich transcripts to plot in retention and non-retention tracks
  if (is_strict){
    tx.ids.nonRetention <- intersect(mytx.ids.e1, mytx.ids.e3) #has both upstream and downstream exons
    
  }else {
    tx.ids.nonRetention <- union(mytx.ids.e1, mytx.ids.e3) #has either upstream and downstream exons
  }
  
  tx.ids.nonRetention <- setdiff(tx.ids.nonRetention, mytx.ids.intron)
  tx.ids.Retention <- mytx.ids.e2
  
  
  # Retention track
  # Recover exons of transcripts for the retention track using transcript IDs
  res <- dplyr::filter(as.data.frame(gtf_exons), transcript_id %in% tx.ids.Retention)
  
  # Create data frame for inclusion track - follow the model from data(geneModels)
  res.df <- res[, c("seqnames", "start", "end", "strand", "exon_id", "transcript_name")]
  colnames(res.df) <- c("chromosome","start","end","strand","exon","transcript")
  
  if (nrow(res.df) > 0){ 
    res.df$feature <- "Retention"
    retention_Track <- Gviz::GeneRegionTrack(range = res.df, name = "Retention", 
                                             transcriptAnnotation = "transcript")  
  }else {
    retention_Track <- Gviz::GeneRegionTrack(range = GRanges(), name = "Retention", 
                                             transcriptAnnotation = "transcript")  
  }
  
  # Non-retention track
  # Recover exons of transcripts for the non-retention track using transcript IDs
  res <- dplyr::filter(as.data.frame(gtf_exons), 
                       transcript_id %in% tx.ids.nonRetention)
  
  # Create data frame for inclusion track - follow the model from data(geneModels)
  res.df <- res[, c("seqnames", "start", "end", "strand", "exon_id", "transcript_name")]
  colnames(res.df) <- c("chromosome","start","end","strand","exon","transcript")
  
  if (nrow(res.df) > 0){
    res.df$feature <- "Non_retention"
    nonRetention_Track <- Gviz::GeneRegionTrack(range = res.df, name = "Non-retention", 
                                                transcriptAnnotation = "transcript",
                                                feature = "Non_Retention")  
  }else {
    nonRetention_Track <- Gviz::GeneRegionTrack(range = GRanges(), name = "Non-retention", 
                                                transcriptAnnotation = "transcript",
                                                feature = "Non_Retention")  
  }
  
  txn_tracks <- list("inclusionTrack" = retention_Track,
                     "skippingTrack" = nonRetention_Track)
  return(txn_tracks)
  
}

createAnnotationTrackMXE_transcripts <- function(eventGr, gtf_exons,
                                                is_strict){
  
  # Transcripts overlapping with splicing event 
  ovl.e1 <- GenomicRanges::findOverlaps(eventGr$exon_1, 
                                        gtf_exons, type = "any")
  ovl.e2 <- GenomicRanges::findOverlaps(eventGr$exon_2, 
                                        gtf_exons, type = "any")
  ovl.e3 <- GenomicRanges::findOverlaps(eventGr$exon_upstream,
                                        gtf_exons, type = "any")
  ovl.e4 <- GenomicRanges::findOverlaps(eventGr$exon_downstream,
                                        gtf_exons, type = "any")
  
  mytx.ids.e1 <- gtf_exons$transcript_id[subjectHits(ovl.e1)]
  mytx.ids.e2 <- gtf_exons$transcript_id[subjectHits(ovl.e2)]
  mytx.ids.e3 <- gtf_exons$transcript_id[subjectHits(ovl.e3)]
  mytx.ids.e4 <- gtf_exons$transcript_id[subjectHits(ovl.e4)]
  
  #obtain intron range for inclusion event and skipping event
  intron.mxe.exon1 <- GenomicRanges::GRanges(seqnames = seqnames(eventGr$exon_1),
                                             ranges = IRanges(
                                               start = c(end(eventGr$exon_upstream) + 1,
                                                         end(eventGr$exon_1) + 1),  
                                               end = c(start(eventGr$exon_1) - 1,
                                                       start(eventGr$exon_downstream) -1)
                                             ),
                                             strand = strand(eventGr$exon_1)
  )
  
  intron.mxe.exon2 <- GenomicRanges::GRanges(seqnames = seqnames(eventGr$exon_2),
                                             ranges = IRanges(
                                               start = c(end(eventGr$exon_upstream) + 1,
                                                         end(eventGr$exon_2) + 1),  
                                               end = c(start(eventGr$exon_2) - 1,
                                                       start(eventGr$exon_downstream) -1)
                                             ),
                                             strand = strand(eventGr$exon_2)
  )
  
  #find transcripts with exons overlapping intronic regions
  ovl.mxe.exon1 <- GenomicRanges::findOverlaps(intron.mxe.exon1, gtf_exons, type = "any")
  mytx.ids.intron1 <- gtf_exons$transcript_id[subjectHits(ovl.mxe.exon1)]
  
  ovl.mxe.exon2 <- GenomicRanges::findOverlaps(intron.mxe.exon2, gtf_exons, type = "any")
  mytx.ids.intron2 <- gtf_exons$transcript_id[subjectHits(ovl.mxe.exon2)]
  
  
  #decide wich transcripts to plot in inclusion and skipping tracks
  if (is_strict){
    mytx.ids.mxe.exon1 <- intersect(mytx.ids.e3, mytx.ids.e4) #has both flanking exons
    mytx.ids.mxe.exon1 <- intersect(mytx.ids.mxe.exon1, mytx.ids.e1) #and exon1
    
    mytx.ids.mxe.exon2 <- intersect(mytx.ids.e3, mytx.ids.e4) #has both flanking exons
    mytx.ids.mxe.exon2 <- intersect(mytx.ids.mxe.exon2, mytx.ids.e2) #and exon2
    
  }else {
    mytx.ids.mxe.exon1 <- union(mytx.ids.e3, mytx.ids.e4) #has either flanking exons
    mytx.ids.mxe.exon1 <- intersect(mytx.ids.mxe.exon1, mytx.ids.e1) #and exon 1
    
    mytx.ids.mxe.exon2 <- union(mytx.ids.e3, mytx.ids.e4) #has both flanking exons
    mytx.ids.mxe.exon2 <- intersect(mytx.ids.mxe.exon2, mytx.ids.e2) #and exon2
  }
  
  #remove transcripts with exons in intronic regions
  mytx.ids.mxe.exon1 <- setdiff(mytx.ids.mxe.exon1, mytx.ids.intron1)
  mytx.ids.mxe.exon2 <- setdiff(mytx.ids.mxe.exon2, mytx.ids.intron2)
  
  
  # MXE Exon 1 track
  # Recover exons of transcripts for the MXE Exon 1 track using transcript IDs
  # AnnotationDbi::keytypes(gtf_txdb)
  res <- dplyr::filter(as.data.frame(gtf_exons), transcript_id %in% mytx.ids.mxe.exon1)
  
  # Create data frame for inclusion track - follow the model from data(geneModels)
  res.df <- res[, c("seqnames", "start", "end", "strand", "exon_id", "transcript_name")]
  colnames(res.df) <- c("chromosome","start","end","strand","exon","transcript")
  
  if (nrow(res.df) > 0){ 
    res.df$feature <- "MXE_Exon1"
    inclusionTrack <- Gviz::GeneRegionTrack(range = res.df, name = "MXE Exon 1", 
                                            transcriptAnnotation = "transcript")  
  }else {
    inclusionTrack <- Gviz::GeneRegionTrack(range = GRanges(), name = "MXE Exon 1", 
                                            transcriptAnnotation = "transcript")  
  }
  
  # MXE Exon 2 track
  # Recover exons of transcripts for the MXE Exon 2 track using transcript IDs
  res <- dplyr::filter(as.data.frame(gtf_exons), transcript_id %in% mytx.ids.mxe.exon2)
  
  # Create data frame for inclusion track - follow the model from data(geneModels)
  res.df <- res[, c("seqnames", "start", "end", "strand", "exon_id", "transcript_name")]
  colnames(res.df) <- c("chromosome","start","end","strand","exon","transcript")
  
  if (nrow(res.df) > 0){
    res.df$feature <- "MXE_Exon2"
    skippingTrack <- Gviz::GeneRegionTrack(range = res.df, name = "MXE Exon 2", 
                                           transcriptAnnotation = "transcript")  
  }else {
    skippingTrack <- Gviz::GeneRegionTrack(range = GRanges(), name = "MXE Exon 2", 
                                           transcriptAnnotation = "transcript")  
  }
  
  txn_tracks <- list("inclusionTrack" = inclusionTrack,
                     "skippingTrack" = skippingTrack)
  return(txn_tracks)
  
}

createAnnotationTrackA5SS_transcripts <- function(eventGr, gtf_exons){
  
  # Transcripts overlapping with splicing event 
  ovl.e1 <- GenomicRanges::findOverlaps(eventGr$exon_short, 
                                        gtf_exons, type = "equal")
  ovl.e2 <- GenomicRanges::findOverlaps(eventGr$exon_long, 
                                        gtf_exons, type = "equal")
  ovl.e3 <- GenomicRanges::findOverlaps(eventGr$exon_flanking, 
                                        gtf_exons, type = "any")
  
  mytx.ids.e1 <- gtf_exons$transcript_id[subjectHits(ovl.e1)]
  mytx.ids.e2 <- gtf_exons$transcript_id[subjectHits(ovl.e2)]
  mytx.ids.e3 <- gtf_exons$transcript_id[subjectHits(ovl.e3)]
  
  #obtain intron range for short event and long event
  intron.short <- GenomicRanges::GRanges(seqnames = seqnames(eventGr$exon_short),
                                            ranges = IRanges(
                                              start = end(eventGr$exon_short) + 1,  
                                              end = start(eventGr$exon_flanking) - 1),
                                            strand = strand(eventGr$exon_short)
  )
  
  intron.long <- GenomicRanges::GRanges(seqnames = seqnames(eventGr$exon_long),
                                         ranges = IRanges(
                                           start = end(eventGr$exon_long) + 1,  
                                           end = start(eventGr$exon_flanking) - 1),
                                         strand = strand(eventGr$exon_long)
  )
  
  
  #find transcripts with exons overlapping intronic regions
  ovl.intron.short <- GenomicRanges::findOverlaps(intron.short, gtf_exons, type = "any")
  mytx.ids.intron.short <- gtf_exons$transcript_id[subjectHits(ovl.intron.short)]
  
  ovl.intron.long <- GenomicRanges::findOverlaps(intron.long, gtf_exons, type = "any")
  mytx.ids.intron.long <- gtf_exons$transcript_id[subjectHits(ovl.intron.long)]
  
  #decide wich transcripts to plot in short and long tracks
  mytx.ids.short <- intersect(mytx.ids.e1, mytx.ids.e3)
  mytx.ids.long <- intersect(mytx.ids.e2, mytx.ids.e3)
  
  #remove transcripts with exons overlapping intronic regions
  mytx.ids.short <- setdiff(mytx.ids.short, mytx.ids.intron.short)
  mytx.ids.long <- setdiff(mytx.ids.long, mytx.ids.intron.long)
  
  # Short track
  # Recover exons of transcripts for the short track using transcript IDs
  # AnnotationDbi::keytypes(gtf_txdb)
  res <- dplyr::filter(as.data.frame(gtf_exons), transcript_id %in% mytx.ids.short)
  
  # Create data frame for inclusion track - follow the model from data(geneModels)
  res.df <- res[, c("seqnames", "start", "end", "strand", "exon_id", "transcript_name")]
  colnames(res.df) <- c("chromosome","start","end","strand","exon","transcript")
  
  if (nrow(res.df) > 0){ 
    res.df$feature <- "A5SS_Short"
    inclusionTrack <- Gviz::GeneRegionTrack(range = res.df, name = "A5SS Short", 
                                            transcriptAnnotation = "transcript")  
  }else {
    inclusionTrack <- Gviz::GeneRegionTrack(range = GRanges(), name = "A5SS Short", 
                                            transcriptAnnotation = "transcript")  
  }
  
  # Long track
  # Recover exons of transcripts for the long track using transcript IDs
  res <- dplyr::filter(as.data.frame(gtf_exons), transcript_id %in% mytx.ids.long)
  
  # Create data frame for inclusion track - follow the model from data(geneModels)
  res.df <- res[, c("seqnames", "start", "end", "strand", "exon_id", "transcript_name")]
  colnames(res.df) <- c("chromosome","start","end","strand","exon","transcript")
  
  if (nrow(res.df) > 0){
    res.df$feature <- "A5SS_Long"
    skippingTrack <- Gviz::GeneRegionTrack(range = res.df, name = "A5SS Long", 
                                           transcriptAnnotation = "transcript")  
  }else {
    skippingTrack <- Gviz::GeneRegionTrack(range = GRanges(), name = "A5SS Long", 
                                           transcriptAnnotation = "transcript")  
  }
  
  txn_tracks <- list("inclusionTrack" = inclusionTrack,
                     "skippingTrack" = skippingTrack)
  return(txn_tracks)
  
}

createAnnotationTrackA3SS_transcripts <- function(eventGr, gtf_exons){
  
  # Transcripts overlapping with splicing event 
  ovl.e1 <- GenomicRanges::findOverlaps(eventGr$exon_short, 
                                        gtf_exons, type = "equal")
  ovl.e2 <- GenomicRanges::findOverlaps(eventGr$exon_long, 
                                        gtf_exons, type = "equal")
  ovl.e3 <- GenomicRanges::findOverlaps(eventGr$exon_flanking, 
                                        gtf_exons, type = "any")
  
  mytx.ids.e1 <- gtf_exons$transcript_id[subjectHits(ovl.e1)]
  mytx.ids.e2 <- gtf_exons$transcript_id[subjectHits(ovl.e2)]
  mytx.ids.e3 <- gtf_exons$transcript_id[subjectHits(ovl.e3)]
  
  #obtain intron range for short event and long event
  intron.short <- GenomicRanges::GRanges(seqnames = seqnames(eventGr$exon_short),
                                         ranges = IRanges(
                                           start = end(eventGr$exon_flanking) + 1,  
                                           end = start(eventGr$exon_short) - 1),
                                         strand = strand(eventGr$exon_short)
  )
  
  intron.long <- GenomicRanges::GRanges(seqnames = seqnames(eventGr$exon_long),
                                        ranges = IRanges(
                                          start = end(eventGr$exon_flanking) + 1,  
                                          end = start(eventGr$exon_long) - 1),
                                        strand = strand(eventGr$exon_long)
  )
  
  
  #find transcripts with exons overlapping intronic regions
  ovl.intron.short <- GenomicRanges::findOverlaps(intron.short, gtf_exons, type = "any")
  mytx.ids.intron.short <- gtf_exons$transcript_id[subjectHits(ovl.intron.short)]
  
  ovl.intron.long <- GenomicRanges::findOverlaps(intron.long, gtf_exons, type = "any")
  mytx.ids.intron.long <- gtf_exons$transcript_id[subjectHits(ovl.intron.long)]
  
  #decide wich transcripts to plot in short and long tracks
  mytx.ids.short <- intersect(mytx.ids.e1, mytx.ids.e3)
  mytx.ids.long <- intersect(mytx.ids.e2, mytx.ids.e3)
  
  #remove transcripts with exons overlapping intronic regions
  mytx.ids.short <- setdiff(mytx.ids.short, mytx.ids.intron.short)
  mytx.ids.long <- setdiff(mytx.ids.long, mytx.ids.intron.long)
  
  # Short track
  # Recover exons of transcripts for the short track using transcript IDs
  # AnnotationDbi::keytypes(gtf_txdb)
  res <- dplyr::filter(as.data.frame(gtf_exons), transcript_id %in% mytx.ids.short)
  
  # Create data frame for inclusion track - follow the model from data(geneModels)
  res.df <- res[, c("seqnames", "start", "end", "strand", "exon_id", "transcript_name")]
  colnames(res.df) <- c("chromosome","start","end","strand","exon","transcript")
  
  if (nrow(res.df) > 0){ 
    res.df$feature <- "A5SS_Short"
    inclusionTrack <- Gviz::GeneRegionTrack(range = res.df, name = "A5SS Short", 
                                            transcriptAnnotation = "transcript")  
  }else {
    inclusionTrack <- Gviz::GeneRegionTrack(range = GRanges(), name = "A5SS Short", 
                                            transcriptAnnotation = "transcript")  
  }
  
  # Long track
  # Recover exons of transcripts for the long track using transcript IDs
  res <- dplyr::filter(as.data.frame(gtf_exons), transcript_id %in% mytx.ids.long)
  
  # Create data frame for inclusion track - follow the model from data(geneModels)
  res.df <- res[, c("seqnames", "start", "end", "strand", "exon_id", "transcript_name")]
  colnames(res.df) <- c("chromosome","start","end","strand","exon","transcript")
  
  if (nrow(res.df) > 0){
    res.df$feature <- "A5SS_Long"
    skippingTrack <- Gviz::GeneRegionTrack(range = res.df, name = "A5SS Long", 
                                           transcriptAnnotation = "transcript")  
  }else {
    skippingTrack <- Gviz::GeneRegionTrack(range = GRanges(), name = "A5SS Long", 
                                           transcriptAnnotation = "transcript")  
  }
  
  txn_tracks <- list("inclusionTrack" = inclusionTrack,
                     "skippingTrack" = skippingTrack)
  return(txn_tracks)
  
}

createAnnotationTrackSE_event <- function(eventGr){
  
  trackGr <- c(unlist(eventGr), unlist(eventGr[2:3]))
  trackGr$group <- rep(c("Inclusion", "Skipping"), c(3, 2))
  trackGr$type <- rep("Exon skipping", 5)
  
  event_track <- Gviz::AnnotationTrack(trackGr, name = "Event", 
                                       groupAnnotation = "group", shape = "box",
                                       stacking = "squish", id = "Exon skipping")
  Gviz::feature(event_track) <- rep(c("Inclusion", "Skipping"), c(3, 2))
  
  
  return(event_track)
  
}

createAnnotationTrackRI_event <- function(eventGr){
  
  trackGr <- c(eventGr$exon_ir, eventGr$exon_upstream, eventGr$exon_downstream)
  trackGr$group <- rep(c("Retention", "Non-retention"), c(1, 2))
  trackGr$type <- rep("Intron retention", 3)
  
  event_track <- Gviz::AnnotationTrack(trackGr, name = "Event", 
                                       groupAnnotation = "group", shape = "box",
                                       stacking = "squish", id = "Intron retention")
  Gviz::feature(event_track) <- rep(c("Retention", "Non_Retention"), c(1, 2))
  
  
  return(event_track)
  
}

createAnnotationTrackMXE_event <- function(eventGr){
  
  trackGr <- c(eventGr$exon_upstream, eventGr$exon_1, eventGr$exon_downstream,
               eventGr$exon_upstream, eventGr$exon_2, eventGr$exon_downstream)
  trackGr$group <- rep(c("MXE_Exon1", "MXE_Exon2"), c(3, 3))
  trackGr$type <- rep("Mutually Exclusive Exons", 3)
  
  event_track <- Gviz::AnnotationTrack(trackGr, name = "Event", 
                                       groupAnnotation = "group", shape = "box",
                                       stacking = "squish", id = "Mutually Exclusive Exons")
  Gviz::feature(event_track) <- rep(c("MXE_Exon1", "MXE_Exon2"), c(3, 3))
  
  
  return(event_track)
  
}

createAnnotationTrackA5SS_event <- function(eventGr){
  
  trackGr <- c(eventGr$exon_short, eventGr$exon_flanking,
               eventGr$exon_long, eventGr$exon_flanking)
  trackGr$group <- rep(c("A5SS Short", "A5SS Long"), c(2, 2))
  trackGr$type <- rep("A5SS", 4)
  
  event_track <- Gviz::AnnotationTrack(trackGr, name = "Event", 
                                       groupAnnotation = "group", shape = "box",
                                       stacking = "squish", id = "A5SS")
  Gviz::feature(event_track) <- rep(c("A5SS_Short", "A5SS_Long"), c(2, 2))
  
  
  return(event_track)
  
}

createAnnotationTrackA3SS_event <- function(eventGr){
  
  trackGr <- c(eventGr$exon_flanking, eventGr$exon_short,
               eventGr$exon_flanking, eventGr$exon_long)
  trackGr$group <- rep(c("A3SS Short", "A3SS Long"), c(2, 2))
  trackGr$type <- rep("A3SS", 4)
  
  event_track <- Gviz::AnnotationTrack(trackGr, name = "Event", 
                                       groupAnnotation = "group", shape = "box",
                                       stacking = "squish", id = "A3SS")
  Gviz::feature(event_track) <- rep(c("A3SS_Short", "A3SS_Long"), c(2, 2))
  
  
  return(event_track)
  
}

createUniprotUCSCtrack_localization <- function(eventGr, genome){
  
  uniprotTracks <- list()
  
  session <- rtracklayer::browserSession("UCSC")
  rtracklayer::genome(session) <- genome
  
  #tableNames(ucscTableQuery(mySession, track="uniprot"))
  # Tables to query in the Uniprot track
  # Creates a track for each table related to cell localization
  tables_uniprot <- c("unipLocExtra", "unipLocTransMemb", 
                      "unipLocCytopl")
  names_uniprot <- c("Extra", "TransMemb", 
                      "Cytop")
  
  #Define region around splicing event
  region <- range(unlist(eventGr))
  start(region) <- start(region) - 10
  end(region) <- end(region) + 10
  genome(region) <- "hg38"
  
  for(i in 1:length(tables_uniprot)){
    
    query <- ucscTableQuery(session, track = "uniprot", table = tables_uniprot[i],
                            range = region)
    query_gr <- rtracklayer::track(query)
    query_table <- rtracklayer::getTable(query)
    
    if (length(query_gr) > 0 ){
      
      track <- Gviz::AnnotationTrack(range = query_gr, genome = genome, 
                                     name = names_uniprot[i], 
                                     id = query_gr$name, 
                                     showFeatureId = TRUE,
                                     fill = query_gr$itemRgb, shape = "arrow")  
        
    }else {
      track <- Gviz::AnnotationTrack(range = GRanges(), name = names_uniprot[i])
    }
    
    uniprotTracks[[tables_uniprot[i]]] <- track  
  }
  
  return(uniprotTracks)  

}