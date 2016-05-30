String.class_eval do
  BLANK_RE = /\A[[:space:]]*\z/
  def blank?
    BLANK_RE === self
  end
end
NilClass.class_eval do
  def blank?
    true
  end
end
