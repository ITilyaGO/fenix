class Xmlp
  UIDZERO = '00000000-0000-0000-0000-000000000000'.freeze

  class << self
    def create_from_file
      fname = "blossom.xml"
      fname = "forpio.xml"
      doc = File.open(fname) { |f| Nokogiri::XML(f) }
      doc.xpath("//V8Exch:Data")[0].children.each do |i|
        next if i.text?
        kind = i.name
        ref = i.xpath('Ref').children.first.content
        xml = i
        parent = i.xpath('Parent').children.first.content if i.xpath('Parent').any?
        cat1 = KSM1C::Cat.new(id: ref)
        cat1.fill(id: ref, kind: kind, ref: ref, xml: xml.to_s, parent: parent)
        cat1.save
      end
    end

    def uuid?(text)
      text =~ /\A[\da-f]{8}-([\da-f]{4}-){3}[\da-f]{12}\z/i
    end
    
  end
end