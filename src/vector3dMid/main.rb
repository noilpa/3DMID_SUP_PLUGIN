require 'sketchup.rb'
require_all 'vector3dMid'




module Examples
  module CustomTool

    Sketchup::require 'vector3dMid/point_tool'
    Sketchup::require 'vector3dMid/safe_sphere'

    unless file_loaded?(__FILE__)
      Sketchup.debug_mode = true
      menu = UI.menu('Plugins')
      submenu = menu.add_submenu('Vector 3D-MID')
      submenu.add_item('Make Point') do
        SKETCHUP_CONSOLE.show
        if SafeSphere.radius == 0
          UI.messagebox('Use safe sphere tool first!', MB_OK)
          return
        end
        Sketchup.active_model.select_tool(PointTool.new)
        puts('Activate_point_tool')
      end
      submenu.add_item('Make Safe Sphere') do
        SKETCHUP_CONSOLE.show
        if SafeSphere.radius != 0
          result = UI.messagebox("Are you sure to update sphere, you lost all points", MB_OKCANCEL)
          if result == IDOK
            File.open(ENV['HOME'] + '/Desktop/points.txt', 'w') { |file| file.truncate(0) }
          else
            return
          end
        end
        Sketchup.active_model.select_tool(SafeSphere.new)
        puts('Activate_safe_sphere_tool')
      end
      file_loaded(__FILE__)
    end
  end # module CustomTool
end # module Examples
