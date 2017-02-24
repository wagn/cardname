# -*- encoding : utf-8 -*-

require 'active_support/configurable'
require 'active_support/inflector'
require 'htmlentities'
require_relative 'smart_name/parts'
require_relative 'smart_name/variants'
require_relative 'smart_name/contextual'

class SmartName < Object
  include Parts
  include Variants
  include Contextual

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
      str =
        if obj.is_a?(Array)
          obj.map(&:to_s) * joint
        else
          obj.to_s
        end
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
    # 1. don't uninflect if the uninflected key is not stable (stabilize = false)
    #    (probably the best choice because you want Matthias not to be the same  as Matthium)
    # 2. uninflect until the key is stable (stabilize = true)
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
  alias simple? simple
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

  # @return true if name starts with the same parts as `prefix`
  def starts_with? prefix
    start_name = prefix.to_name
    start_name == self[0, start_name.length]
  end
  alias_method :start_with?, :starts_with?

  # @return true if name has a chain of parts that equals `subname`
  def include? subname
    subkey = subname.to_name.key
    joint = Regexp.quote self.class.joint
    key =~ /(^|#{joint})#{Regexp.quote subkey}($|#{joint})/
  end

  # ~~~~~~~~~~~~~~~~~~~~ MISC ~~~~~~~~~~~~~~~~~~~~

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
