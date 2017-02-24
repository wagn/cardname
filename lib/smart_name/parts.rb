class SmartName
   module Parts
     def junction?
       !simple?
     end

     def left
       @left ||= simple? ? nil : parts[0..-2] * self.class.joint
     end

     def right
       @right ||= simple? ? nil : parts[-1]
     end

     def left_name
       @left_name ||= left && self.class.new(left)
     end

     def right_name
       @right_name ||= right && self.class.new(right)
     end

     # Note that all names have a trunk and tag,
     # but only junctions have left and right

     def trunk
       @trunk ||= simple? ? s : left
     end

     def tag
       @tag ||= simple? ? s : right
     end

     def trunk_name
       @trunk_name ||= simple? ? self : left_name
     end

     def tag_name
       @tag_name ||= simple? ? self : right_name
     end

     def part_names
       @part_names ||= parts.map(&:to_name)
     end

     def piece_names
       @piece_names ||= pieces.map(&:to_name)
     end

     def pieces
       @pieces ||=
         if simple?
           [self]
         else
           junction_pieces = []
           parts[1..-1].inject parts[0] do |left, right|
             piece = [left, right] * self.class.joint
             junction_pieces << piece
             piece
           end
           parts + junction_pieces
         end
     end

     def replace_part oldpart, newpart
       oldpart = oldpart.to_name
       newpart = newpart.to_name
       if oldpart.simple?
         if simple?
           self == oldpart ? newpart : self
         else
           parts.map do |p|
             oldpart == p ? newpart.to_s : p
           end.to_name
         end
       elsif simple?
         self
       else
         if oldpart == parts[0, oldpart.length]
           if length == oldpart.length
             newpart
           else
             (newpart.parts + parts[oldpart.length..-1]).to_name
           end
         else
           self
         end
       end
     end

     alias_method :to_a, :parts

     # name parts can be accessed and manipulated like an array
     # but no implicit conversion to array
     # otherwise ["A+B", "C"].flatten => ["A", "B", "C"]
     def method_missing method, *args, &block
       if parts.respond_to?(method) && method != :to_ary
         self.class.new parts.send(method, *args, &block)
       else
         super
       end
     end

     def respond_to? method, include_private=false
       super || (method != :to_ary && parts.respond_to?(method, include_private))
     end
   end
end
