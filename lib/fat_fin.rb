# frozen_string_literal: true

require "debug"

require "date"
require "fat_core/all"
require "fat_core/date"
require "bigdecimal/util"

require_relative "fat_fin/version"

module FatFin
  class Error < StandardError; end

  require "core_ext/date"
  require "fat_fin/payment"
  require "fat_fin/cash_flow"
end
