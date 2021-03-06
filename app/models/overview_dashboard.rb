class OverviewDashboard
  def results
    available_stats.each_with_object({}) do |(stat_name, calculator), h|
      h[stat_name] = calculator.call
    end
  end

  private
  def available_stats
    {
      'counts_by_evidence_type'              => ->() { EvidenceItem.count_by_evidence_type },
      'counts_by_evidence_level'             => ->() { EvidenceItem.count_by_evidence_level },
      'counts_by_evidence_direction'         => ->() { EvidenceItem.count_by_evidence_direction },
      'counts_by_variant_origin'             => ->() { EvidenceItem.count_by_variant_origin },
      'counts_by_clinical_significance'      => ->() { EvidenceItem.count_by_clinical_significance },
      'counts_by_rating'                     => ->() { EvidenceItem.group(:rating).count },
      'counts_by_status'                     => ->() { EvidenceItem.group(:status).count },
      'top_journals_with_levels'             => ->() { count_eids_by_field(top_journals, :journal, :evidence_level) },
      'top_journals_with_types'              => ->() { count_eids_by_field(top_journals, :journal, :evidence_type) },
      'top_diseases_with_levels'             => ->() { count_eids_by_field(top_diseases, :display_name, :evidence_level) },
      'top_diseases_with_types'              => ->() { count_eids_by_field(top_diseases, :display_name, :evidence_type) },
      'top_drugs_with_levels'                => ->() { count_eids_by_field(top_drugs, :name, :evidence_level) },
      'top_drugs_with_clinical_significance' => ->() { count_eids_by_field(top_drugs, :name, :clinical_significance) },
      'count_by_source_publication_year'     => method(:count_by_publication_year),
    }
  end

  def count_eids_by_field(objs, key, enumerated_field)
    objs.each_with_object({}) do |entity, h|
      counts = {}
      EvidenceItem.where(id: entity.eids)
        .group(enumerated_field)
        .count
        .each { |(k,v)| next if k.blank?; counts[EvidenceItem.send(enumerated_field.to_s.pluralize).key(k).downcase] = v }
      h[entity.send(key)] = counts
    end
  end

  def top_drugs
    @top_drugs ||= Drug.joins(:evidence_items)
      .group('drugs.name')
      .select('drugs.name, array_agg(distinct(evidence_items.id)) as eids')
      .order('count(distinct(evidence_items.id)) desc')
      .limit(25)
  end

  def top_diseases
    @top_diseases ||= Disease.joins(:evidence_items)
      .group('diseases.display_name')
      .select('diseases.display_name, array_agg(evidence_items.id) as eids')
      .order('count(distinct(evidence_items.id)) desc')
      .limit(25)
  end

  def top_journals
    @top_journals ||= Source.joins(:evidence_items)
      .group('sources.journal')
      .select('sources.journal, array_agg(evidence_items.id) as eids')
      .order('count(distinct(evidence_items.id)) desc')
      .limit(25)
  end

  def count_by_publication_year
    {}.tap do |counts|
      Source.joins(:evidence_items)
        .group('sources.publication_year')
        .where.not(publication_year: nil)
        .select('sources.publication_year, count(distinct(evidence_items.id)) as evidence_item_count')
        .order('publication_year asc').each_with_object(counts) do |source, counts|
          counts[source.publication_year] = source.evidence_item_count unless source.evidence_item_count == 0
        end
    end
  end
end
