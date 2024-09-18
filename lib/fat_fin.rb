# frozen_string_literal: true

require "debug"

require "date"
class << Date
  def ensure(other)
    ensure_date(other)
  end
end

# Namespace module for the financial classes and methods implemented in this
# library.
module FatFin
  class Error < StandardError; end

  require_relative "fat_fin/version"
  require "fat_core/all"
  require "fat_period"
  require "core_ext/date"
  require "fat_fin/time_value"
  require "fat_fin/cash_flow"
  require "fat_fin/annuity"
  require "fat_fin/bond"
end
