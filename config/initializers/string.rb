class String
  def starts_with(needle)
    self[0..(needle.length - 1)] == needle
  end
end
