# ==============================================================================
# CABINETRIX AI — GOLA DRAWER BANK MASTER (SKETCHUP WRAPPER)
# ==============================================================================
require 'sketchup.rb'
require 'json'

load File.join(__dir__, '..', 'gemini', 'gola_drawer_bank_master.rb')

CabinetrixGolaDrawerBank = CabinetrixMasterGola unless defined?(CabinetrixGolaDrawerBank)
