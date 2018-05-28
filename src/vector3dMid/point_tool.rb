require 'sketchup.rb'

module Examples
  module CustomTool
    class PointTool

      def activate
        puts('Activate vector')
        @mouse_ip = Sketchup::InputPoint.new
        update_ui
      end

      def deactivate(view)
        puts('Deactivate vector')
        view.invalidate
      end

      def resume(view)
        update_ui
        view.invalidate
      end

      def onCancel(_reason, view)
        puts('Canceled vector')
        view.invalidate
      end

      # If you are on a face, then the degrees_of_freedom will be 2 meaning that you can only move on the plane of the
      # face.
      # If you are on an Edge or an axis, then the degrees_of_freedom will be 1 meaning that you can only move in the
      # direction of the edge or axis.
      # If you get an end point of an Edge, or an intersection point, then the degrees_of_freedom will be 0.

      def onMouseMove(_flags, x, y, view)
        @mouse_ip.pick(view, x, y, @mouse_ip)
        dof = @mouse_ip.degrees_of_freedom
        view.tooltip = @mouse_ip.tooltip if @mouse_ip.valid? && dof < 3
        view.invalidate
      end

      def onLButtonDown(_flags, _x, _y, view)
        puts('OnLButtonDown vector')
        dof = @mouse_ip.degrees_of_freedom
        get_vector_normal if @mouse_ip.valid? && dof < 3
        update_ui
        view.invalidate
      end

      # Here we have hard coded a special ID for the pencil cursor in SketchUp.
      # Normally you would use `UI.create_cursor(cursor_path, 0, 0)` instead
      # with your own custom cursor bitmap:
      #
      #   CURSOR_PENCIL = UI.create_cursor(cursor_path, 0, 0)
      CURSOR_POINT = 632
      def onSetCursor
        UI.set_cursor(CURSOR_POINT)
      end

      def draw(view)
        draw_preview(view)
        @mouse_ip.draw(view) if @mouse_ip.display?
      end

      private

      def update_ui
        Sketchup.status_text = 'Select point on plane.'
      end

      def draw_preview(view)
        view.draw(GL_POINTS, @mouse_ip)
      end

      def calc_intersection_point(pos, normal)
        r = SafeSphere.radius
        return nil if r == 0
        r = r.to_inch
        xc, yc, zc = SafeSphere.center_point.to_a
        a, b, g = normal.to_a
        x, y, z = pos

        puts "===========calculation============"
        puts "radius = #{r}"
        puts "center point = #{xc} #{yc} #{zc}"
        puts "line vector = #{normal.to_a}"
#        puts "line vector normalized = #{normal.normalize.to_a}"
        puts "point = #{pos}"
        puts "=================================="
        root = root(a,b,g,xc,yc,zc,x,y,z,r)
        coef = coefficient(a, b, g)


        t = coef*(-a*x + a*xc - b*y + b*yc - g*z + g*zc + 0.5 * root)
        puts "t = #{t}"

        # t1 = coef*(-a*x + a*xc - b*y + b*yc + g*z - 0.5 * root - g*zc)
        # puts "t1 = #{t1}"

        if t.is_a?(Complex)
          UI.messagebox('Square root is complex number! Perhaps the selected point is outside the sphere', MB_OK)
          return nil
        end

        if t < 0
          t = coef*(-a*x + a*xc - b*y + b*yc - g*z + g*zc - 0.5 * root)
          puts "t = #{t}"
        end

        xs = x + a*t
        ys = y + b*t
        zs = z + g*t

        puts "xs = #{xs} ys = #{ys} zs = #{zs}"
        puts "==========end_of_calc=============\n"
        Geom::Point3d.new(xs, ys, zs)

      end

      def root(a,b,g,xc,yc,zc,x,y,z,r)
        ((4*(a*(xc - x) + b*(yc - y) + g*(zc - z))**2) -
            4*((a**2) + (b**2) + (g**2))*(-(r**2) + ((x - xc)**2) + ((y - yc)**2) + ((z - zc)**2)))**0.5
      end

      def coefficient(a, b, g)
        (1/((a**2) + (b**2) + (g**2)))
      end

      def calc_const_point(pos, normal)
        a, b, g = normal.to_a
        x, y, z = pos
        const = 100
        puts "========calc_const_point========"
        puts "line vector = #{normal.to_a}"
        puts "point = #{pos}"

        xs = x + a*const
        ys = y + b*const
        zs = z + g*const

        puts "xs = #{xs} ys = #{ys} zs = #{zs}"
        puts "======end_calc_const_point======"

        Geom::Point3d.new(xs, ys, zs)
      end




      def visualize(point1, point2)
        # puts 'visualize'
        # puts "=====visualize_begin====="
        # puts "point1 = #{point1}"
        # puts "point2 = #{point2}"
        # puts "========================="
        model = Sketchup.active_model
        model.start_operation('Edge', true)
        edge = model.active_entities.add_line(point1, point2)
        model.commit_operation
        # puts "=====visualize_end====="
        # puts "point1 = #{point1}"
        # puts "point2 = #{point2}"
        # puts "======================="
      end


      def get_vector_normal
        puts('Get vector normal')
        face = @mouse_ip.face
        normal = face.normal
        # vector3d.axes
        # The axes method is used to compute an arbitrary set of axes with the given vector as the z-axis direction.
        # Returns an Array of three vectors [xaxis, yaxis, zaxis].
        #
        # The position method is used to get the 3D point from the input point.
        # The values are specified as [x,y,z].
        axes = normal.axes
        pos = @mouse_ip.position
        puts "pose on surface = #{pos.to_a}"
        sphere_pos = calc_intersection_point(pos.to_a, normal)
#        sphere_pos = calc_const_point(pos.to_a, normal)
        return 0 if sphere_pos.nil?
        puts "sphere pos = #{sphere_pos.to_a}\n"
        visualize(pos, sphere_pos)
        puts "===========points_coordinates============="
        puts("#{pos[0]},#{pos[1]},#{pos[2]},#{normal[0]},#{normal[1]},#{normal[2]}")
        puts("#{sphere_pos[0]},#{sphere_pos[1]},#{sphere_pos[2]},#{normal[0]},#{normal[1]},#{normal[2]}")
        puts "==========================================\n"

        # "#{'%.2f' % var}"

        file = File.open(ENV['HOME'] + '/Desktop/points.txt', 'a')
        file.puts("Vector\n#{'%.5f' % pos[0].to_mm},#{'%.5f' % pos[1].to_mm},#{'%.5f' % pos[2].to_mm}")
        file.puts("#{'%.5f' % sphere_pos[0].to_mm}, #{'%.5f' % sphere_pos[1].to_mm}, #{'%.5f' % sphere_pos[2].to_mm}")
        file.puts("#{normal[0]}, #{normal[1]},#{normal[2]}")
        file.close
      end

    end # class PointTool
  end
end

