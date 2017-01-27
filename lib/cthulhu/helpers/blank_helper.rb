module Cthulhu
  refine String do
    BLANK_RE = /\A[[:space:]]*\z/
    def blank?
      BLANK_RE === self
    end
  end
  refine NilClass do
    def blank?
      true
    end
  end
end
