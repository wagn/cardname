# -*- encoding : utf-8 -*-

require 'active_support/configurable'
require 'active_support/inflector'
require 'htmlentities'

class SmartName < Object
  RUBYENCODING = RUBY_VERSION !~ /^1\.8/
  OK4KEY_RE    = RUBYENCODING ? '\p{Word}\*' : '\w\*'

  include ActiveSupport::Configurable

  config_accessor :joint, :banned_array, :var_re, :uninflect, :params, :session, :stabilize

  SmartName.joint          = '+'
  SmartName.banned_array   = ['/', '~', '|']
  SmartName.var_re         = /\{([^\}]*\})\}/
  SmartName.uninflect      = :singularize
  SmartName.stabilize      = false       
  

  JOINT_RE = Regexp.escape joint

  @@name2nameobject = {}

  class << self
    def new obj
      return obj if obj.is_a? self.class
      str = obj.is_a?(Array) ? obj * joint : obj.to_s
      if (known_name = @@name2nameobject[str])
        known_name
      else
        super str.strip
      end
    end

    def banned_re
      %r{#{ (['['] + banned_array << joint) * '\\' + ']' }}
    end
    
    # Sometimes the core rule "the key's key must be itself" (called "stable" below) is violated
    # eg. it fails with singularize as uninflect method for Matthias -> Matthia -> Matthium
    # Usually that means the name is a proper noun and not a plural.
    # You can choose between two solutions:
    # 1. don't uninflect if the uninflected key is not stable (stabelize = false)
    #    (probably the best choice because you want Matthias not to be the same  as Matthium)
    # 2. uninflect until the key is stable (stabelize = true)
    def stable_uninflect name
      key_one = name.send(SmartName.uninflect)
      key_two = key_one.send(SmartName.uninflect)
      return key_one unless key_one != key_two
      SmartName.stabilize ? stable_uninflect(key_two) : name
    end
  end

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # ~~~~~~~~~~~~~~~~~~~~~~ INSTANCE ~~~~~~~~~~~~~~~~~~~~~~~~~

  attr_reader :simple, :parts, :key, :s
  alias to_s s

  def initialize str
    @s = str.to_s.strip
    @s = @s.encode('UTF-8') if RUBYENCODING
    @key = if @s.index(self.class.joint)
             @parts = @s.split(/\s*#{JOINT_RE}\s*/)
             @parts << '' if @s[-1, 1] == self.class.joint
             @simple = false
             @parts.map { |p| p.to_name.key } * self.class.joint
           else
             @parts = [str]
             @simple = true
             str.empty? ? '' : simple_key
           end
    @@name2nameobject[str] = self
  end

  def to_name
    self
  end

  def length
    parts.length
  end

  def size
    to_s.size
  end

  def blank?
    s.blank?
  end
  alias empty? blank?

  def valid?
    !parts.find do |pt|
      pt.match self.class.banned_re
    end
  end

  def inspect
    "<#{self.class.name} key=#{key}[#{self}]>"
  end

  def == other
    other_key =
      case
      when other.respond_to?(:key)     then other.key
      when other.respond_to?(:to_name) then other.to_name.key
      else                                  other.to_s
      end
    other_key == key
  end

  # ~~~~~~~~~~~~~~~~~~~ VARIANTS ~~~~~~~~~~~~~~~~~~~

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

  # ~~~~~~~~~~~~~~~~~~~ PARTS ~~~~~~~~~~~~~~~~~~~

  alias simple? simple
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

  # ~~~~~~~~~~~~~~~~~~~~ SHOW / ABSOLUTE ~~~~~~~~~~~~~~~~~~~~

  def to_show *ignore
    ignore.map!(&:to_name)

    show_parts = parts.map do |part|
      reject = (part.empty? || (part =~ /^_/) || ignore.member?(part.to_name))
      reject ? nil : part
    end

    show_name = show_parts.compact.to_name.s

    case
    when show_parts.compact.empty? then  self
    when show_parts[0].nil?        then  self.class.joint + show_name
    else show_name
    end
  end

  def to_absolute context, args={}
    context = context.to_name
    parts.map do |part|
      new_part =
        case part
        when /^_user$/i
          name_proc = self.class.session
          name_proc ? name_proc.call : part
        when /^_main$/i            then self.class.params[:main_name]
        when /^(_self|_whole|_)$/i then context.s
        when /^_left$/i            then context.trunk
          # note - inconsistent use of left v. trunk
        when /^_right$/i           then context.tag
        when /^_(\d+)$/i
          pos = $~[1].to_i
          pos = context.length if pos > context.length
          context.parts[pos - 1]
        when /^_(L*)(R?)$/i
          l_s, r_s = $~[1].size, !$~[2].empty?
          l_part = context.nth_left l_s
          r_s ? l_part.tag : l_part.s
        # when /^_/
        #   custom = args[:params] ? args[:params][part] : nil
        #   custom ? CGI.escapeHTML(custom) : part
        # why are we escaping HTML here?
        else
          part
        end.to_s.strip
      new_part.empty? ? context.to_s : new_part
    end * self.class.joint
  end

  def to_absolute_name *args
    self.class.new to_absolute(*args)
  end

  def nth_left n
    # 1 = left; 2= left of left; 3 = left of left of left....
    (n >= length ? parts[0] : parts[0..-n - 1]).to_name
  end

  # ~~~~~~~~~~~~~~~~~~~~ MISC ~~~~~~~~~~~~~~~~~~~~

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

  # HACK. This doesn't belong here.
  # shouldn't it use inclusions???
  def self.substitute! str, hash
    hash.keys.each do |var|
      str.gsub! var_re do |x|
        hash[var.to_sym]
      end
    end
    str
  end
end
