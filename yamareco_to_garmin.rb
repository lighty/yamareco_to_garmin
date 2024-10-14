# frozen_string_literal: true

require 'rexml/document'
require 'optparse'

TYPE_CONVERT_TABLE = {
  '1' => 'SUMMIT',     # (頂上) -> 山頂/峠(SUMMIT) 
  '2' => 'SUMMIT',     # (峠) -> 山頂/峠(SUMMIT)
  '3' => 'CHECKPOINT', # (分岐) -> チェックポイント(CHECKPOINT)
  '4' => 'CHECKPOINT', # (登山口) -> チェックポイント(CHECKPOINT)
  '5' => 'REST AREA',  # (山小屋) -> 休憩エリア(REST AREA)
  '6' => 'CAMPSITE',   # (テント場) -> キャンプ場(CAMPSITE)
  '7' => 'WATER',      # (水場) -> ウォーター(WATER)
  '9' => 'REST AREA',  # (お風呂) -> 休憩エリア(REST AREA)
  '11' => 'OVERLOOK',  # (展望ポイント) -> 展望スポット(OVERLOOK)
  '12' => 'TRANSPORT', # (バス停) -> 交通機関(TRANSPORT)
  '13' => 'TRANSPORT', # (駐車場) -> 交通機関(TRANSPORT)
  '14' => 'TOILET'     # (トイレ) -> トイレ(TOILET)
}.freeze

def convert_type(yamareco_types)
  # Priority needs to be adjusted
  TYPE_CONVERT_TABLE[yamareco_types&.first] || 'CHECKPOINT'
end

def extract_way_points(trk)
  trk.elements['trkseg'].elements.map do |trkpt|
    next if trkpt.elements['name'].nil?

    REXML::Element.new('wpt').tap do |wpt|
      wpt.add_attribute('lat', trkpt.attribute('lat').value)
      wpt.add_attribute('lon', trkpt.attribute('lon').value)
      wpt.add_element(trkpt.elements['ele'].clone)
      name = @options[:elevation] ? trkpt.elements['ele'].text + trkpt.elements['name'].text : trkpt.elements['name'].text
      name = @options[:yomi] ? name : name.gsub(/ \[.*/, '')
      wpt.add_element(REXML::Element.new('name').tap { _1.text = name })
      wpt.add_element(REXML::Element.new('type').tap { _1.text = convert_type(trkpt.elements['type']&.text&.split(',')) })
    end
  end.compact
end

def add_way_points(doc, wpts)
  wpts.each { doc.root.add_element(_1) }
end

def output(doc, name)
  formatter = REXML::Formatters::Pretty.new
  formatter.compact = true
  if @options[:'output-file'].nil?
    formatter.write(doc, $stdout)
  else
    File.open("#{name}_" + @options[:'output-file'], 'w') do |file|
      formatter.write(doc, file)
    end
  end
end

def set_option
  @options = {}
  parser = OptionParser.new do |opt|
    opt.on('-i YAMARECO_GPX_FILE', '--input-file', 'specify gpx file downloaded from yamareco.')
    opt.on('-o [GARMIN_GPX_FILE]', '--output-file', 'specify output file. if no specify, output it to stdout.')
    opt.on('--[no-]elevation', '[do not] add elevation into name.')
    opt.on('--[no-]yomi', '[do not] add yomi into name.')
  end
  parser.parse!(ARGV, into: @options)
  # can't write `@options[:elevation] || true` because @options[:elevation] can be not only nil but false and use false value if so.
  @options[:elevation] = @options[:elevation].nil? ? true : @options[:elevation]
  @options[:yomi] = @options[:yomi].nil? ? true : @options[:yomi]
  abort 'specify gpx file downloaded from yamareco.' if @options[:'input-file'].nil?
end

def build_name_by_trk(trk)
  summits = trk.elements['trkseg'].elements.select do |trkpt|
    !trkpt.elements['name'].nil? && convert_type(trkpt.elements['type']&.text&.split(',')) == 'SUMMIT'
  end
  return summits.first.elements['name'].text.gsub(/ \[.*/, '') if summits.size < 2

  "#{trk.elements['name'].text} - #{summits.first.elements['name'].text.gsub(/ \[.*/, '')} - #{summits.last.elements['name'].text.gsub(/ \[.*/, '')}"
end

set_option
doc = REXML::Document.new(File.open(@options[:'input-file']))
doc.root.elements.each do |trk|
  out_doc = REXML::Document.new
  out_doc.add_element(doc.root.clone)
  out_doc.root.add_element(trk.deep_clone)
  wpts = extract_way_points(trk)
  out_doc.root.elements['trk'].elements['name'].text = build_name_by_trk(trk)
  wpts.each { out_doc.root.add_element(_1) }
  # TODO: When there is only one trk, convert the first and last summit to a name.
  output(out_doc, trk.elements['name'].text)
end
