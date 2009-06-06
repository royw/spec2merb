  def started_at=(datetime)
    datetime = nil if datetime.blank?
    attribute_set(:started_at, datetime)
  end

  def finished_at=(datetime)
    datetime = nil if datetime.blank?
    attribute_set(:finished_at, datetime)
  end
