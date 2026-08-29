# =============================================================================
# Cabinex AI — SketchUp Extension Loader
# Version: 5.0.0
# Author:  Cabinex AI (https://cabinex-cloud.vercel.app)
# =============================================================================
require 'sketchup.rb'
require 'extensions.rb'

module CabinexAI
  EXTENSION_VERSION = '5.0.0'
  EXTENSION_NAME    = 'Cabinex AI Kitchen Designer'

  unless file_loaded?(__FILE__)
    ex = SketchupExtension.new(
      EXTENSION_NAME,
      File.join('cabinex_ai', 'loader.rb')
    )
    ex.description = 'AI-powered full-aluminum kitchen configurator with 3D model generation, ' \
                     'workshop reports, bar cut plans, and cloud licensing. ' \
                     'Strictly All-Aluminum: Premium BoxBar + 45° Sash and Economy Frame + ACP.'
    ex.version     = EXTENSION_VERSION
    ex.creator     = 'Cabinex AI'
    ex.copyright   = "© #{Time.now.year} Cabinex AI — All rights reserved."
    Sketchup.register_extension(ex, true)
    file_loaded(__FILE__)
  end
end
