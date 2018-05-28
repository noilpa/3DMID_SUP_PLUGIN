require 'sketchup.rb'
require 'extensions.rb'

module Examples
  module CustomTool


    unless file_loaded?(__FILE__)
      ex = SketchupExtension.new('Point Tool', 'vector3dMid/main')
      ex.description = 'SketchUp plugin for 3D MID and URobots collaboration'
      ex.version     = '1.0.0'
      ex.copyright   = 'IU4 © 2017'
      ex.creator     = 'NoviokvIP'
      Sketchup.register_extension(ex, true)
      file_loaded(__FILE__)
    end


  end # module CustomTool
end # module Examples