class SmartName
  module Variants
    def simple_key
      decoded
        .underscore
        .gsub(/[^#{OK4KEY_RE}]+/, '_')
        .split(/_+/)
        .reject(&:empty?)
        .map { |key| SmartName.stable_uninflect(key) }
        .join('_')
    end

    def url_key
      @url_key ||= part_names.map do |part_name|
        stripped = part_name.decoded.gsub(/[^#{OK4KEY_RE}]+/, ' ').strip
        stripped.gsub(/[\s\_]+/, '_')
      end * self.class.joint
    end

    def safe_key
      @safe_key ||= key.tr('*', 'X').tr self.class.joint, '-'
    end

    def decoded
      @decoded ||= s.index('&') ? HTMLEntities.new.decode(s) : s
    end
  end
end
