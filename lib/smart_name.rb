# -*- encoding : utf-8 -*-

require 'active_support/configurable'
require 'active_support/inflector'
require 'htmlentities'
require 'date'
require 'sort64'

class SmartName < Object
  RUBYENCODING = RUBY_VERSION !~ /^1\.8/
  OK4KEY_RE    = RUBYENCODING ? '\p{Word}\*' : '\w\*'

  DAYS = (Date::ABBR_DAYNAMES + Date::DAYNAMES).map(&:downcase).to_set
  MONTHS = (1..12).each_with_object({}) do |idx, hash|
    hash[Date::ABBR_MONTHNAMES[idx].downcase] = hash[Date::MONTHNAMES[idx].downcase] = idx
  end

  DATE_FORMAT = '%D'
  DATETIME_FORMAT = '%c'

  include ActiveSupport::Configurable

  config_accessor :joint, :name_attribute, :banned_array, :var_re, :uninflect, :params, :session

  # Wagny defaults:
  #config_accessor :joint,        :default => '+'
  SmartName.joint          = '+'
  SmartName.banned_array   = [ '/', '~', '|' ]
  SmartName.name_attribute = :cardname
  SmartName.var_re         = /\{([^\}]*\})\}/
  SmartName.uninflect      = :singularize
  #SmartName.special_keys   = &(SmartName.special_keys)

  JOINT_RE = Regexp.escape joint

  @@name2nameobject = {}

  class << self
    def new obj
      return obj if self.class===obj
      str = Array===obj ? obj*joint : obj.to_s
      if known_name = @@name2nameobject[str]
        known_name
      else
        super str.strip
      end
    end

    def banned_re
      %r{#{ (['['] + banned_array << joint )*'\\' + ']' }}
    end

    def special_keys key
      key_parts = key.split('_')
      idx = 0
      max_idx = key_parts.size - 2
      while (idx < max_idx) do
        if DAYS.include?(key_parts[idx])
          if match_result = date_time_match(key_parts[idx+1..idx+3], key_parts[idx+4..-1])
            date_time_key, part_count = match_result
            key_parts[idx..idx+4+part_count] = date_time_key
            key = key_parts * '_'
          end
          break
        elsif match_result = date_time_match(key_parts[idx..idx+2], key_parts[idx+3..-1])
          date_time_key, part_count = match_result
          key_parts[idx..idx+3+part_count] = date_time_key
          key = key_parts * '_'
          break
        end
        idx += 1
      end

      if key !~ /\D/
        key = "Q#{Sort64.encode64 key.to_i}"
      elsif key_parts.size > 1 && key_parts.any?{|kp| kp !~ /\D/}
        key = key_parts.map{|kp| kp =~ /\D/ ? kp : "L#{Sort64.encode32 kp.to_i}"}*'_'
      end
      key
    end

    def date_time_match date_parts, time_parts
      y_idx = date_parts.index {|p| p =~ /^\d{4}$/}
      if [0, 2].include? y_idx
        if y_idx == 2
          date_parts = date_parts[2], date_parts[1], date_parts[0]
          m_idx=nil
          (0..date_parts.length-1).find do |idx|
            if month = MONTHS[date_parts[idx].downcase]
              date_parts[m_idx = idx] = month.to_s
            end
          end
          date_parts[2], date_parts[1] = date_parts[1], date_parts[2] if m_idx == 0 || date_parts[1].to_i > 12
        end

        num_time_parts = 0
        if time_parts.first =~ /^([ap]m)?(\d{1,2})([ap]m)?$/i
          min = sec = 0
          h = $2.to_i
          if $3 # HH[AP]M
            num_time_parts, hour, am_pm = 1, h, $3 unless $1 || h > 12
          elsif $1 && h <= 12 || h <= 23 # [[AP]M]HH[:MM:SS]
            hour, am_pm = h, $1
          end
          if hour
            if num_time_parts == 0
              if time_parts[1]
                if time_parts[1] =~ /^(\d{1,2})([ap]m)?$/i && $1.to_i < 60
                  if $2 # HH:MM[AP]M
                    num_time_parts, min, am_pm = 2, $1.to_i, $2 unless am_pm
                  else # [[AP]M]HH:MM[:SS]
                    min = $1.to_i
                  end
                  if time_parts[2]
                    if time_parts[2] =~ /^(\d{1,2})([ap]m)?$/i && $1.to_i < 60
                      am_pm_new, s = $2, $1.to_i
                      if !am_pm_new && time_parts[3] && time_parts[3] =~ /^[ap]m$/i
                        num_time_parts, sec, am_pm = 4, s, time_parts[3]
                      elsif !(am_pm_new && am_pm)
                        num_time_parts, sec, am_pm = 3, $1.to_i, am_pm_new
                      end
                    elsif !am_pm && time_parts[2] =~ /^[ap]m$/i
                      num_time_parts, ap_pm = 3, time_parts[2]
                    end
                  end
                elsif !am_pm && time_parts[1] =~ /^[ap]m$/i
                  num_time_parts, ap_pm = 2, time_parts[1]
                end
              end
            end
            if am_pm
              hour = 0 if hour == 12
              hour += 12 if ['p', 'P'].include? am_pm[0]
            end
          end
          hms = [hour, min, sec]
        end
        unless date_parts.any? {|p| p=~/\D/}
          hms ||= [0, 0, 0]
          time = Time.new(*(date_parts.map(&:to_i)), *hms, '+00:00')
          if num_time_parts > 0
            ["T#{Sort64.encode64 time.to_i}", num_time_parts]
          else
            ["D#{Sort64.encode32 time.to_date.jd}", 0]
          end
        end
      end
    rescue ArgumentError => e
      nil
    end
  end


  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  #~~~~~~~~~~~~~~~~~~~~~~ INSTANCE ~~~~~~~~~~~~~~~~~~~~~~~~~

  attr_reader :simple, :parts, :key, :s
  alias to_s s

  def initialize str
    @s = str.to_s.strip
    @s = @s.encode('UTF-8') if RUBYENCODING
    @key = if @s.index(self.class.joint)
        @parts = @s.split(/\s*#{JOINT_RE}\s*/)
        @parts << '' if @s[-1,1] == self.class.joint
        @simple = false
        @parts.map { |p| p.to_name.key } * self.class.joint
      else
        @parts = [str]
        @simple = true
        str.empty? ? '' : self.class.special_keys( simple_key )
      end
    @@name2nameobject[str] = self
  end

  def to_name()    self         end
  def length()     parts.length end
  def size()       to_s.size    end
  def blank?()     s.blank?     end
  alias empty? blank?

  def valid?
    not parts.find do |pt|
      pt.match self.class.banned_re
    end
  end

  def inspect
    "<#{self.class.name} key=#{key}[#{self}]>"
  end

  def == obj
    object_key = case
      when obj.respond_to?(:key)     ; obj.key
      when obj.respond_to?(:to_name) ; obj.to_name.key
      else                           ; obj.to_s
      end
    object_key == key
  end


  #~~~~~~~~~~~~~~~~~~~ VARIANTS ~~~~~~~~~~~~~~~~~~~

  def simple_key
    decoded.underscore.gsub(/[^#{OK4KEY_RE}]+/,'_').split(/_+/).reject(&:empty?).map(&(self.class.uninflect))*'_'
  end

  def url_key
    @url_key ||= decoded.gsub(/[^#{OK4KEY_RE}#{JOINT_RE}]+/,' ').strip.gsub /[\s\_]+/, '_'
  end

  def safe_key
    @safe_key ||= key.gsub('*','X').gsub self.class.joint, '-'
  end

  def decoded
    @decoded ||= (s.index('&') ?  HTMLEntities.new.decode(s) : s)
  end

  def pretty_key
    parts.map do |part|
      part.to_name.key.split('_').map do |kp|
        if kp =~ /^[A-Z]/ && value = Sort64.decode($')
          case $&
            when 'D'
              'Date: '      + Date.jd(value).strftime(DATE_FORMAT)
            when 'T'
              'Datetime: '  + Time.at(value).getutc.strftime(DATETIME_FORMAT)
            when 'L'
              'Long: '      + value.to_s
            when 'Q'
              'Long Long: ' + value.to_s
          end
        else
          kp
        end
      end * '::'
    end * " #{self.class.joint} "
  end

  def pre_cgi
    #why is this necessary?? doesn't real CGI escaping handle this??
    # hmmm.  is this to prevent absolutizing
    @pre_cgi ||= parts.join '~plus~'
  end

  def post_cgi
    #hmm.  this could resolve to the key of some other card.  move to class method?
    @post_cgi ||= s.gsub '~plus~', self.class.joint
  end

  #~~~~~~~~~~~~~~~~~~~ PARTS ~~~~~~~~~~~~~~~~~~~

  alias simple? simple
  def junction?()   not simple?                                             end

  def left()        @left  ||= simple? ? nil : parts[0..-2]*self.class.joint end
  def right()       @right ||= simple? ? nil : parts[-1]                    end

  def left_name()   @left_name   ||= left  && self.class.new( left  )        end
  def right_name()  @right_name  ||= right && self.class.new( right )        end

  # Note that all n ames have a trunk and tag, but only junctions have left and right

  def trunk()       @trunk ||= simple? ? s : left                           end
  def tag()         @tag   ||= simple? ? s : right                          end

  def trunk_name()  @trunk_name  ||= simple? ? self : left_name             end
  def tag_name()    @tag_name    ||= simple? ? self : right_name            end

  def part_names()  @part_names  ||= parts.map  &:to_name                   end
  def piece_names() @piece_names ||= pieces.map &:to_name                   end

  def pieces
    @pieces ||= if simple?
      [ self ]
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



  #~~~~~~~~~~~~~~~~~~~~ SHOW / ABSOLUTE ~~~~~~~~~~~~~~~~~~~~

  def to_show *ignore
    ignore.map! &:to_name

    show_parts = parts.map do |part|
      reject = ( part.empty? or part =~ /^_/ or ignore.member? part.to_name )
      reject ? nil : part
    end

    show_name = show_parts.compact.to_name.s

    case
    when show_parts.compact.empty?;  self
    when show_parts[0].nil?       ;  self.class.joint + show_name
    else show_name
    end
  end


  def to_absolute context, args={}
    context = context.to_name
    parts.map do |part|
      new_part = case part
        when /^_user$/i;            name_proc = self.class.session and name_proc.call or part
        when /^_main$/i;            self.class.params[:main_name]
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
    end * self.class.joint
  end

  def to_absolute_name *args
    self.class.new to_absolute(*args)
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
          ( newpart.parts + parts[ oldpart.length..-1 ] ).to_name
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
