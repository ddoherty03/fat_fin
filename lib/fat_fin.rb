# frozen_string_literal: true

require 'bundler/setup'
Bundler.setup

# Gem Overview (extracted from README.org by gem_docs)
#
# * Introduction
# This gem, ~fat_fin~ aims at providing a serviceable library for performing
# financial calculations, including time-value-of-money calculations.
module FatFin
  class Error < StandardError; end

  require_relative "fat_fin/version"
  require "fat_period"
  require "fat_fin/core_ext"
  require "fat_fin/cash_point"
  require "fat_fin/cash_flow"
  require "fat_fin/annuity"
  require "fat_fin/bond"
end
