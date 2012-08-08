xml.instruct!
xml.definitions 'xmlns' => 'http://schemas.xmlsoap.org/wsdl/',
                'xmlns:tns' => @namespace,
                'xmlns:soap' => 'http://schemas.xmlsoap.org/wsdl/soap/',
                'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                'xmlns:wsdl' => 'http://schemas.xmlsoap.org/wsdl/',
                'name' => @name,
                'targetNamespace' => @namespace do
  xml.types do
    xml.tag! "schema", :targetNamespace => @namespace, :xmlns => 'http://www.w3.org/2001/XMLSchema' do
      defined = []
      @map.each do |operation, formats|
        xml.tag! "xsd:element", :name => operation do
          xml.tag! "xsd:complexType" do
            xml.tag! "xsd:sequence" do
              formats[:in].each do |p|
                xml.tag! "xsd:element", wsdl_occurence(p, false, :name => p.name, :type => p.namespaced_type)
              end
            end
          end
        end
        xml.tag! "xsd:element", :name => "#{operation}_response" do
          xml.tag! "xsd:complexType" do
            xml.tag! "xsd:sequence" do
              formats[:out].each do |p|
                xml.tag! "xsd:element", wsdl_occurence(p, false, :name => p.name, :type => p.namespaced_type)
              end
            end
          end
        end
        # define complex types
        (formats[:in] + formats[:out]).each do |p|
          wsdl_type xml, p, defined
        end
      end
    end
  end

  xml.portType :name => "#{@name}_port" do
    @map.keys.each do |operation|
      xml.operation :name => operation do
        xml.input :message => "tns:#{operation}_request"
        xml.output :message => "tns:#{operation}_response"
      end
    end
  end

  xml.binding :name => "#{@name}_binding", :type => "tns:#{@name}_port" do
    xml.tag! "soap:binding", :style => 'document', :transport => 'http://schemas.xmlsoap.org/soap/http'
    @map.keys.each do |operation|
      xml.operation :name => operation do
        xml.tag! "soap:operation", :soapAction => operation, :style => 'document'
        xml.input do
          xml.tag! "soap:body", :use => 'literal'
        end
        xml.output do
          xml.tag! "soap:body", :use => 'literal'
        end
      end
    end
  end

  xml.service :name => "service" do
    xml.port :name => "#{@name}_port", :binding => "tns:#{@name}_binding" do
      xml.tag! "soap:address", :location => url_for(:action => '_action', :only_path => false)
    end
  end

  @map.each do |operation, formats|
    xml.message :name => "#{operation}_request" do
      xml.part :name => 'parameters', :element => "tns:#{operation}"
    end
    xml.message :name => "#{operation}_response" do
      xml.part :name => 'parameters', :element => "tns:#{operation}_response"
    end
  end
end
