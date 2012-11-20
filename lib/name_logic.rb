# -*- encoding : utf-8 -*-

require 'active_support/configurable'
require 'active_support/inflector'

class Object
  def to_name() NameLogic.new(self) end
end

class NameLogic < Object
  require 'htmlentities'
  RUBY19            = RUBY_VERSION =~ /^1\.9/
  WORD_RE           = RUBY19 ? '\p{Word}' : '\w'

  include ActiveSupport::Configurable

  config_accessor :joint, :formal_joint, :name_attribute, :banned_array,
    :var_re, :uninflect, :params, :codes, :lookup

  # Wagny defaults:
  JOINT                    = '+'
  NameLogic.joint          = JOINT
  NameLogic.formal_joint   = " <span class=\"wiki-joint\">#{JOINT}</span> "
  NameLogic.banned_array   = [ '/', '~', '|' ]
  NameLogic.name_attribute = :cardname
  NameLogic.var_re         = /\{([^\}]*})\}/
  NameLogic.uninflect      = :singularize

  @@name2nameobject = {}

  class << self
    def new obj
      return obj if NameLogic===obj
      str = Array===obj ? obj*NameLogic.joint : obj.to_s
      if known_name = @@name2nameobject[str]
        known_name
      else
        super str.strip
      end
    end

    def unescape uri
      # can't instantiate because key doesn't resolve correctly in unescaped form
      # issue is peculiar to plus sign (+), which are interpreted as a space.
      # if we could make that not happen, we could avoid this (and handle spaces in urls)
      uri.gsub(' ','+').gsub '_',' '
    end

    def banned_re
      %r{#{ (['['] + NameLogic.banned_array << NameLogic.joint )*'\\' + ']' }}
    end
  end


  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  #~~~~~~~~~~~~~~~~~~~~~~ INSTANCE ~~~~~~~~~~~~~~~~~~~~~~~~~

  attr_reader :simple, :parts, :key, :s
  alias to_s s

  def initialize str
    @s = str.to_s.strip
    @s = @s.encode('UTF-8') if RUBY19
    @key = if @s.index(NameLogic.joint)
        @parts = @s.split(/\s*#{Regexp.escape(NameLogic.joint)}\s*/)
        @parts << '' if @s[-1] == NameLogic.joint
        @simple = false
        @parts.map { |p| p.to_name.key } * NameLogic.joint
      else
        @parts = [str]
        @simple = true
        str.empty? ? '' : simple_key
      end
    @@name2nameobject[str] = self
  end

  def valid?()
    not parts.find { |pt| pt.match NameLogic.banned_re }
  end
  def to_name()    self         end
  def length()     parts.length end
  def size()       to_s.size    end
  def blank?()     s.blank?     end
  alias empty? blank?

  def inspect
    "<NameLogic key=#{key}[#{self}]>"
  end

  def == obj
    object_key = case
      when obj.respond_to?(:key)      ; obj.key
      when obj.respond_to?(:to_name) ; obj.to_name.key
      else                               ; obj.to_s
      end
    object_key == key
  end


  #~~~~~~~~~~~~~~~~~~~ VARIANTS ~~~~~~~~~~~~~~~~~~~

  def simple_key
    decoded.underscore.gsub(/[^#{WORD_RE}\*]+/,'_').split(/_+/).reject(&:empty?).map(&(NameLogic.uninflect))*'_'
  end

  def url_key
    @url_key ||= decoded.gsub(/[^\*#{WORD_RE}\s\+]/,' ').strip.gsub(/[\s\_]+/,'_')
  end

  def safe_key
    @safe_key ||= key.gsub('*','X').gsub NameLogic.joint, '-'
  end

  def decoded
    @decoded ||= (s.index('&') ?  HTMLEntities.new.decode(s) : s)
  end

    def pre_cgi
      #why is this necessary?? doesn't real CGI escaping handle this??
      # hmmm.  is this to prevent absolutizing
      @pre_cgi ||= parts.join '~plus~'
    end

    def post_cgi
      #hmm.  this could resolve to the key of some other card.  move to class method?
      @post_cgi ||= s.gsub '~plus~', NameLogic.joint
    end

    #~~~~~~~~~~~~~~~~~~~ PARTS ~~~~~~~~~~~~~~~~~~~

    alias simple? simple
    def junction?()  not simple?                                             end

    def left()       @left  ||= simple? ? nil : parts[0..-2]*NameLogic.joint end
    def right()      @right ||= simple? ? nil : parts[-1]                    end

    def left_name()  @left_name  ||= left  && NameLogic.new( left  )         end
    def right_name() @right_name ||= right && NameLogic.new( right )         end

    # Note that all names have a trunk and tag, but only junctions have left and right

    def trunk()      @trunk ||= simple? ? s : left                           end
    def tag()        @tag   ||= simple? ? s : right                          end

    def trunk_name() @trunk_name ||= simple? ? self : left_name              end
    def tag_name()   @tag_name   ||= simple? ? self : right_name             end

    def pieces
      @pieces ||= if simple?
        [ self ]
      else
        trunk_name.pieces + [ tag_name ]
      end
    end


    #~~~~~~~~~~~~~~~~~~~ TRAITS / STARS ~~~~~~~~~~~~~~~~~~~

  def star?()         simple?   and '*' == s[0]               end
  def rstar?()        right     and '*' == right[0]           end

  def trait_name? *traitlist
    junction? && begin
      right_key = right_name.key
      !!traitlist.find do |codename|
        codecard = NameLogic.codes[ codename ] and codecard = NameLogic.lookup[ codecard ] and
          codecard.send(NameLogic.name_attribute).key == right_key
      end
    end
  end

  def trait_name tag_code
    codecard = NameLogic.codes[ tag_code ] and codecard = NameLogic.lookup[ codecard ] and
      [ self, codecard.send(NameLogic.name_attribute) ].to_name
  end

  def trait tag_code
    trait_name( tag_code ).s
  end



  #~~~~~~~~~~~~~~~~~~~~ SHOW / ABSOLUTE ~~~~~~~~~~~~~~~~~~~~

  def to_show context, args={}
#      ignore = [ args[:ignore], context.to_name.parts ].flatten.compact.map &:to_name
    ignore = [ args[:ignore] ].flatten.map &:to_name
    fullname = parts.to_name.to_absolute_name context, args

    show_parts = fullname.parts.map do |part|
      reject = ( part.empty? or part =~ /^_/ or ignore.member? part.to_name )
      reject ? nil : part
    end

    initial_blank = show_parts[0].nil?
    show_name = show_parts.compact.to_name.s

    initial_blank ? NameLogic.joint + show_name : show_name
  end


  def to_absolute context, args={}
    context = context.to_name
    parts.map do |part|
      new_part = case part
        when /^_user$/i;            (user=Session.user_card) ? user.name : part
        when /^_main$/i;            NameLogic.params[:main_name]
        when /^(_self|_whole|_)$/i; context.s
        when /^_left$/i;            context.trunk #note - inconsistent use of left v. trunk
        when /^_right$/i;           context.tag
        when /^_(\d+)$/i
          pos = $~[1].to_i
          pos = context.length if pos > context.length
          context.parts[pos-1]
        when /^_(L*)(R?)$/i
          l_s, r_s = $~[1].size, !$~[2].empty?
          l_part = context.nth_left l_s
          r_s ? l_part.tag : l_part.s
        when /^_/
          custom = args[:params] ? args[:params][part] : nil
          custom ? CGI.escapeHTML(custom) : part #why are we escaping HTML here?
        else
          part
        end.to_s.strip
      new_part.empty? ? context.to_s : new_part
    end * NameLogic.joint
  end

  def to_absolute_name *args
    NameLogic.new to_absolute(*args)
  end

  def nth_left n
    # 1 = left; 2= left of left; 3 = left of left of left....
    ( n >= length ? parts[0] : parts[0..-n-1] ).to_name
  end


  #~~~~~~~~~~~~~~~~~~~~ MISC ~~~~~~~~~~~~~~~~~~~~

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
        if self.length == oldpart.length
          newpart
        else
          (newpart.parts+(parts[oldpart.length,].lines.to_a)).to_name
        end
      else
        self
      end
    end
  end

  def self.substitute! str, hash
    hash.keys.each do |var|
      str.gsub!(NameLogic.var_re) { |x| (v=hash[var.to_sym]).nil? ? x : v }
    end
    str
  end

end
