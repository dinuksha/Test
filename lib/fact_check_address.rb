require "plek"

class FactCheckAddress
  DOMAIN = "alphagov.co.uk"

  def for_edition(edition)
    "#{prefix}#{edition.id}@#{DOMAIN}"
  end

  def regexp
    /#{prefix}(.+?)@#{DOMAIN}/
  end

  private
  def prefix
    "factcheck+#{environment}-"
  end

  # Fact check email addresses are environment dependent. This is
  # a bad thing, but changing it would be very disruptive. Since
  # Plek no longer gives us access to the environment we have to rely
  # on the fact that the environment is included in the public domain
  # name for an app.
  def environment
    Plek.current.find('publisher').split('.')[1]
  end
end