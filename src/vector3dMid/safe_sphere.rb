require 'sketchup.rb'

module Examples
  module CustomTool
    class SafeSphere
      @@radius = 0

      def self.radius
        @@radius
      end

      def self.center_point
        @@center_point
      end

      def activate

        @mouse_ip = Sketchup::InputPoint.new
        @picked_first_ip = Sketchup::InputPoint.new
        update_ui
      end

      def deactivate(view)
        view.invalidate
      end

      def resume(view)
        update_ui
        view.invalidate
      end

      def onCancel(_reason, view)
        reset_tool
        view.invalidate
      end

      def onMouseMove(_flags, x, y, view)

        if picked_first_point?
#          puts 'picked_first_point? valid'
          @mouse_ip.pick(view, x, y, @picked_first_ip)
          puts @mouse_ip
        else
          @mouse_ip.pick(view, x, y)
        end
        view.tooltip = @mouse_ip.tooltip if @mouse_ip.valid?
        view.invalidate
      end

      def onLButtonDown(_flags, _x, _y, view)
        puts 'onLButtonDown'
        num_new_faces = 0
        if picked_first_point?
          puts("num_new_faces = create_edge")
          num_new_faces = create_edge
        end
        if num_new_faces > 0
          puts("reset_tool")
        else
          puts("@picked_first_ip.copy!(@mouse_ip)")
          @picked_first_ip.copy!(@mouse_ip)
        end
        update_ui
        view.invalidate
      end

      # Here we have hard coded a special ID for the pencil cursor in SketchUp.
      # Normally you would use `UI.create_cursor(cursor_path, 0, 0)` instead
      # with your own custom cursor bitmap:
      #
      #   CURSOR_PENCIL = UI.create_cursor(cursor_path, 0, 0)
      CURSOR_PENCIL = 632
      def onSetCursor
        # Note that `onSetCursor` is called frequently so you should not do much
        # work here. At most you switch between different cursors representing
        # the state of the tool.
        UI.set_cursor(CURSOR_PENCIL)
      end

      # The `draw` method is called every time SketchUp updates the viewport.
      # You should take care to do as little work in this method as possible.
      # If you need to calculate things to draw it is best to cache the data in
      # order to get better frame rates.
      def draw(view)
        draw_preview(view)
        @mouse_ip.draw(view) if @mouse_ip.display?
      end

      # When you use `view.draw` and draw things outside the boundingbox of
      # the existing model geometry you will see that things get clipped.
      # In order to make sure everything you draw is visible you must return
      # a boundingbox here which defines the 3d model space you draw to.
      # def getExtents
      #   bb = Geom::BoundingBox.new
      #   bb.add(picked_points)
      #   bb
      # end

      # In this example we put all the logic in the tool class itself. For more
      # complex tools you probably want to move that logic into its own class
      # in order to reduce complexity. If you are familiar with the MVC pattern
      # then consider a tool class a controller - you want to keep it short and
      # simple.

      private

      def update_ui
        Sketchup.status_text = if picked_first_point?
                                 'Select radius.'
                               else
                                 'Select сenter point.'
                               end
      end

      def reset_tool
        @picked_first_ip.clear
        update_ui
      end

      def picked_first_point?
        @picked_first_ip.valid?

      end

      def picked_points
        points = []
        points << @picked_first_ip.position if picked_first_point?
        points << @mouse_ip.position if @mouse_ip.valid?
        points
      end

      def draw_preview(view)
        points = picked_points
        return unless points.size == 2
        view.set_color_from_line(*points)
        view.line_width = 1
        view.line_stipple = ''
        view.draw(GL_LINE_LOOP, points)
      end

      # start_operation(op_name, disable_ui = false, next_transparent = false, transparent = false) ⇒ Boolean

      def create_edge
        model = Sketchup.active_model
        model.start_operation('Edge', true)
        @@center_point = picked_points[0]
        normal = @@center_point.vector_to(picked_points[1])
        normal.length = 1
        @@radius = @@center_point.vector_to(picked_points[1]).length
        puts("Center: #{@@center_point}\nRadius: #{@@radius}")
        edge = model.active_entities.add_circle(@@center_point, normal, @@radius, 100)
        file = File.open(ENV['HOME'] + '/Desktop/points.txt', 'w')
        file.puts("Sphere\n#{'%.5f' % @@center_point[0].to_mm},#{'%.5f' % @@center_point[1].to_mm},#{'%.5f' % @@center_point[2].to_mm}\n#{'%.5f' % @@radius.to_mm}\n")
        file.close
        model.commit_operation
        1
      end
    end # class SafeSphere
  end
end
