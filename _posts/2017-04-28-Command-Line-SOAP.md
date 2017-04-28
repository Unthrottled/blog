---
layout: post
title:  "SOAP Requests without SoapUI"
date:   2017-4-28
categories: soap
---

There are times when one might be unable to obtain access to SoapUI to help debug/test a deployed SOAP web service.
While it is vastly easier to interact with your web service's API with the neat Smart Bear gadget, all hope is not lost!

If you are not familiar with SOAP or want a quick refresher here is a snippet from wikipedia

>SOAP (originally Simple Object Access Protocol) is a protocol specification for exchanging structured information 
in the implementation of web services in computer networks. 
...
It uses XML Information Set for its message format, 
and relies on application layer protocols, most often Hypertext Transfer Protocol (HTTP)
    
Having access to a Unix's command line with the curl command already or able to be installed is a work around to not having SoapUI.

Curl's manual states:

>curl  is  a  tool to transfer data from or to a server, using one of the supported protocols (DICT, FILE, FTP,
FTPS, GOPHER, HTTP, HTTPS, IMAP, IMAPS, LDAP, LDAPS, POP3, POP3S, RTMP, RTSP,  SCP,  SFTP,  SMB,  SMBS,  SMTP,
SMTPS, TELNET and TFTP).
       
Well look at that, it handles HTTP requests! 

If you do not have _curl_ on you machine, all you have to do (assuming you have sudo permission) is run:

    sudo apt-get install curl

    
Before going any further, I have provided a sample web service that I will be referencing for the rest of the post.

It can be found on git hub here:

[https://github.com/cyclic-reference/web-service-sample](https://github.com/cyclic-reference/web-service-sample)

To run the sample you will need:
 - Internet Connection (At least the first time it is run)
 - [Java 8 runtime](http://www.oracle.com/technetwork/java/javase/downloads/index.html)
 - [Gradle 2.3+ ](https://gradle.org/install)


Most web services I have interacted with involve me creating a request from the defined schema and sending them to the web service.
The act of sending a request has almost always been in the from of an HTTP POST request.
This can be determined just by looking the headers of a SOAP request. Here is a sample: 

    POST http://sandwich:8400/computer-service HTTP/1.1 
    Accept-Encoding: gzip,deflate
    Content-Type: text/xml;charset=UTF-8
    SOAPAction: ""
    Content-Length: 236
    Host: sandwich:8400
    Connection: Keep-Alive
    User-Agent: Apache-HttpClient/4.1.1 (java 1.5)

There is quite a bit going on there, but the important bits will be highlighted.
The first line denotes that a POST request was sent to the endpoint 
    
    http://sandwich:8400/computer-service 

Where sandwich is the hostname of the server the web service is hosted on (which happens to be the name of my local host).
The web service is located on port 8400 under the _computer-service_ endpoint 

The format of the content that this request is expecting xml, which is denoted by

    Content-Type: text/xml;charset=UTF-8


The example service method dose not have a SOAPAction associated with it. 
Which was denoted by `SOAPAction: ""`. 
This is important, because if method, you try to call, has a SOAP action associated with it that changes the command we need to run.

Lastly, the web service definition is a follows:

{% highlight xml  %}
<?xml version="1.0" encoding="UTF-8" standalone="no"?><wsdl:definitions xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" xmlns:sch="http://acari.io/simple/web-service" xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:tns="http://acari.io/simple/web-service" targetNamespace="http://acari.io/simple/web-service">
  <wsdl:types>
    <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified" targetNamespace="http://acari.io/simple/web-service">

    <xs:element name="getAllComputerRequest">
        <xs:complexType>
            <xs:sequence/>
        </xs:complexType>
    </xs:element>

    <xs:element name="getAllComputerResponse">
        <xs:complexType>
            <xs:sequence>
                <xs:element maxOccurs="unbounded" name="computer" type="tns:computer"/>
            </xs:sequence>
        </xs:complexType>
    </xs:element>



    <xs:complexType name="computer">
        <xs:sequence>
            <xs:element name="model" type="xs:string"/>
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
  <wsdl:message name="getAllComputerRequest">
    <wsdl:part element="tns:getAllComputerRequest" name="getAllComputerRequest">
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="getAllComputerResponse">
    <wsdl:part element="tns:getAllComputerResponse" name="getAllComputerResponse">
    </wsdl:part>
  </wsdl:message>
  <wsdl:portType name="ComputersPort">
    <wsdl:operation name="getAllComputer">
      <wsdl:input message="tns:getAllComputerRequest" name="getAllComputerRequest">
    </wsdl:input>
      <wsdl:output message="tns:getAllComputerResponse" name="getAllComputerResponse">
    </wsdl:output>
    </wsdl:operation>
  </wsdl:portType>
  <wsdl:binding name="ComputersPortSoap11" type="tns:ComputersPort">
    <soap:binding style="document" transport="http://schemas.xmlsoap.org/soap/http"/>
    <wsdl:operation name="getAllComputer">
      <soap:operation soapAction=""/> <!-- No SOAP Action, but other might have one! -->
      <wsdl:input name="getAllComputerRequest">
        <soap:body use="literal"/>
      </wsdl:input>
      <wsdl:output name="getAllComputerResponse">
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

A request can be created from the above definition which should look a little like this:

{% highlight xml  %}
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" 
xmlns:web="http://acari.io/simple/web-service">
   <soapenv:Header/>
   <soapenv:Body>
      <web:getAllComputerRequest/>
   </soapenv:Body>
</soapenv:Envelope>
{% endhighlight %}

This can be save into a file called request.xml or it can be converted into a really long string like so

{% highlight xml  %}
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:web="http://acari.io/simple/web-service"><soapenv:Header/><soapenv:Body><web:getAllComputerRequest/></soapenv:Body></soapenv:Envelope>
{% endhighlight %}

Now we have every thing we need to create a _curl_ command to make a SOAP request!
Which should look like this:

    curl --header "content-type: text/xml" -d @request.xml http://sandwich:8400/computer-service


Time for a breakdown:

- --header "content-type: text/xml": tells the server that the client will only accept xml as a response.
- -d @request.xml: -d is the argument for an HTTP POST request and @request.xml tells curl to use the file request.xml in the current working directory.
- http://sandwich:8400/computer-service is the URL of the deployed web service.

Running the command (provided you have change the url to the fully qualified path to the sample web service and have request.xml in the current working) will output this blob to the command line:

{% highlight xml  %}
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"><SOAP-ENV:Header/><SOAP-ENV:Body><ns2:getAllComputerResponse xmlns:ns2="http://acari.io/simple/web-service"><ns2:computer><ns2:model>Blade Stealth</ns2:model><ns2:ram>16</ns2:ram><ns2:make>Razer</ns2:make><ns2:cores>TWO</ns2:cores></ns2:computer><ns2:computer><ns2:model>Blade Pro</ns2:model><ns2:ram>16</ns2:ram><ns2:make>Razer</ns2:make><ns2:cores>FOUR</ns2:cores></ns2:computer><ns2:computer><ns2:model>Macbook Air</ns2:model><ns2:ram>8</ns2:ram><ns2:make>Apple</ns2:make><ns2:cores>FOUR</ns2:cores></ns2:computer><ns2:computer><ns2:model>Macbook Pro</ns2:model><ns2:ram>16</ns2:ram><ns2:make>Apple</ns2:make><ns2:cores>EIGHT</ns2:cores></ns2:computer><ns2:computer><ns2:model>XPS 13</ns2:model><ns2:ram>8</ns2:ram><ns2:make>Dell</ns2:make><ns2:cores>TWO</ns2:cores></ns2:computer></ns2:getAllComputerResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>
{% endhighlight %}

There are tools to pretty print xml on the command line. 
One such tool is `xml_pp`, where pp is pretty print. 
It can be installed (if necessary) by running 

    sudo apt-get install xml-twig-tools
    
Now all that is needed is to pipe the output of the SOAP request into xml_pp.

    curl --header "content-type: text/xml" -d @request.xml http://sandwich:8400/computer-service | xml_pp

Which outputs a nice and indented xml response:

{% highlight xml  %}
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
  <SOAP-ENV:Header/>
  <SOAP-ENV:Body>
    <ns2:getAllComputerResponse xmlns:ns2="http://acari.io/simple/web-service">
      <ns2:computer>
        <ns2:model>Blade Stealth</ns2:model>
        <ns2:ram>16</ns2:ram>
        <ns2:make>Razer</ns2:make>
        <ns2:cores>TWO</ns2:cores>
      </ns2:computer>
      <ns2:computer>
        <ns2:model>Blade Pro</ns2:model>
        <ns2:ram>16</ns2:ram>
        <ns2:make>Razer</ns2:make>
        <ns2:cores>FOUR</ns2:cores>
      </ns2:computer>
      <ns2:computer>
        <ns2:model>Macbook Air</ns2:model>
        <ns2:ram>8</ns2:ram>
        <ns2:make>Apple</ns2:make>
        <ns2:cores>FOUR</ns2:cores>
      </ns2:computer>
      <ns2:computer>
        <ns2:model>Macbook Pro</ns2:model>
        <ns2:ram>16</ns2:ram>
        <ns2:make>Apple</ns2:make>
        <ns2:cores>EIGHT</ns2:cores>
      </ns2:computer>
      <ns2:computer>
        <ns2:model>XPS 13</ns2:model>
        <ns2:ram>8</ns2:ram>
        <ns2:make>Dell</ns2:make>
        <ns2:cores>TWO</ns2:cores>
      </ns2:computer>
    </ns2:getAllComputerResponse>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
{% endhighlight %}

Using the really long string instead of the file can be done as such:

    curl --header "content-type: text/xml" -d '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:web="http://acari.io/simple/web-service"><soapenv:Header/><soapenv:Body><web:getAllComputerRequest/></soapenv:Body></soapenv:Envelope>' http://sandwich:8400/computer-service | xml_pp