module WashOutHelper
  def wsdl_data(xml, params)
    params.each do |param|
      tag_name = "#{param.name}"

      if !param.struct?
        if !param.multiplied
          xml.tag! tag_name, param.value, "xsi:type" => param.namespaced_type
        else
          param.value = [] unless param.value.is_a?(Array)
          param.value.each do |v|
            xml.tag! tag_name, v, "xsi:type" => param.namespaced_type
          end
        end
      else
        if !param.multiplied
          xml.tag! tag_name, "xsi:type" => param.namespaced_type do
            wsdl_data(xml, param.map)
          end
        else
          xml.tag! tag_name, "xmlns:soap-enc" => "http://schemas.xmlsoap.org/soap/encoding/",
                             "soap-enc:arrayType" => "#{param.namespaced_type.singularize}[#{param.map.size}]",
                             "xsi:type" => "soap-enc:Array" do
            param.map.each do |p|
              xml.tag! 'item' do
                wsdl_data(xml, p.map)
              end
            end
          end
        end
      end
    end
  end

  def wsdl_type(xml, param, defined=[])
    more = []

    if param.struct?
      if !defined.include?(param.basic_type)
        xml.tag! "xsd:complexType", :name => (param.multiplied ? param.basic_type.singularize : param.basic_type) do
          xml.tag! "xsd:sequence" do
            param.map.each do |value|
              more << value if value.struct?
              xml.tag! "xsd:element", wsdl_occurence(value, false, :name => value.name, :type => value.namespaced_type)
            end
          end
        end
        if param.multiplied
          xml.tag! "xsd:complexType", :name => param.basic_type.pluralize do
            xml.tag! "xsd:complexContent" do
              xml.tag! "xsd:restriction", :base => "soap-enc:Array" do
                xml.tag! "xsd:attribute", :ref => "soap-enc:arrayType", :"wsdl:arrayType" => "tns:#{param.basic_type.singularize}[]"
              end
            end
          end
        end

        defined << param.basic_type
      elsif !param.classified?
        raise RuntimeError, "Duplicate use of `#{param.basic_type}` type name. Consider using classified types."
      end
    end

    more.each do |p|
      wsdl_type xml, p, defined
    end
  end

  def wsdl_occurence(param, inject, extend_with = {})
    data = !param.multiplied ? {} : {
      "#{'xsi:' if inject}minOccurs" => 0,
      "#{'xsi:' if inject}maxOccurs" => 'unbounded'
    }

    extend_with.merge(data)
  end
end
