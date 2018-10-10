---
layout: post
---

WSDL
---



{% highlight xml  %}
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<wsdl:definitions xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" 
    xmlns:sch="http://acari.io/simple/web-service" 
    xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" 
    xmlns:tns="http://acari.io/simple/web-service" 
    targetNamespace="http://acari.io/simple/web-service">
  <wsdl:types>
    <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" 
        elementFormDefault="qualified" 
        targetNamespace="http://acari.io/simple/web-service">

    <xs:element name="allComputersRequest">
        <xs:complexType>
            <xs:sequence/>
        </xs:complexType>
    </xs:element>

    <xs:element name="allComputersResponse">
        <xs:complexType>
            <xs:sequence>
                <xs:element maxOccurs="unbounded" name="computers" type="tns:computer"/>
            </xs:sequence>
        </xs:complexType>
    </xs:element>

    <xs:element name="computersByModelRequest">
        <xs:complexType>
            <xs:sequence>
                <xs:element minOccurs="1" name="model" type="xs:string"/>
            </xs:sequence>
        </xs:complexType>
    </xs:element>

    <xs:element name="computersByModelResponse">
        <xs:complexType>
            <xs:sequence>
                <xs:element maxOccurs="unbounded" name="computers" type="tns:computer"/>
            </xs:sequence>
        </xs:complexType>
    </xs:element>


    <xs:complexType name="computer">
        <xs:sequence>
            <xs:element name="model" type="xs:string"/>
            <xs:element name="subModel" type="xs:string"/>
            <xs:element name="ram" type="xs:int"/>
            <xs:element name="make" type="xs:string"/>
            <xs:element name="cores" type="tns:cores"/>
        </xs:sequence>
    </xs:complexType>

    <xs:simpleType name="cores">
        <xs:restriction base="xs:string">
            <xs:enumeration value="TWO"/>
            <xs:enumeration value="FOUR"/>
            <xs:enumeration value="EIGHT"/>
        </xs:restriction>
    </xs:simpleType>
</xs:schema>
  </wsdl:types>
  <wsdl:message name="allComputersRequest">
    <wsdl:part element="tns:allComputersRequest" name="allComputersRequest">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="computersByModelRequest">
    <wsdl:part element="tns:computersByModelRequest" name="computersByModelRequest">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="allComputersResponse">
    <wsdl:part element="tns:allComputersResponse" name="allComputersResponse">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="computersByModelResponse">
    <wsdl:part element="tns:computersByModelResponse" name="computersByModelResponse">
    </wsdl:part>
  </wsdl:message>
  <wsdl:portType name="ComputersPort">
    <wsdl:operation name="allComputers">
      <wsdl:input message="tns:allComputersRequest" name="allComputersRequest">
    </wsdl:input>
      <wsdl:output message="tns:allComputersResponse" name="allComputersResponse">
    </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="computersByModel">
      <wsdl:input message="tns:computersByModelRequest" name="computersByModelRequest">
    </wsdl:input>
      <wsdl:output message="tns:computersByModelResponse" name="computersByModelResponse">
    </wsdl:output>
    </wsdl:operation>
  </wsdl:portType>
  <wsdl:binding name="ComputersPortSoap11" type="tns:ComputersPort">
    <soap:binding style="document" transport="http://schemas.xmlsoap.org/soap/http"/>
    <wsdl:operation name="allComputers">
      <soap:operation soapAction=""/>
      <wsdl:input name="allComputersRequest">
        <soap:body use="literal"/>
      </wsdl:input>
      <wsdl:output name="allComputersResponse">
        <soap:body use="literal"/>
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="computersByModel">
      <soap:operation soapAction="http://acari.io/simple/web-service/computersByModel"/>
      <wsdl:input name="computersByModelRequest">
        <soap:body use="literal"/>
      </wsdl:input>
      <wsdl:output name="computersByModelResponse">
        <soap:body use="literal"/>
      </wsdl:output>
    </wsdl:operation>
  </wsdl:binding>
  <wsdl:service name="ComputersPortService">
    <wsdl:port binding="tns:ComputersPortSoap11" name="ComputersPortSoap11">
      <soap:address location="http://sandwich:8400/computer-service"/>
    </wsdl:port>
  </wsdl:service>
</wsdl:definitions>
{% endhighlight %}