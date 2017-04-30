---
layout: post
title:  "SOAP Requests without SoapUI"
date:   2017-4-28
categories: soap
---

There are times when one might be unable to obtain access to [SoapUi](https://www.soapui.org/downloads/soapui.html) to help debug/test a deployed SOAP web service.
While it is vastly easier to interact with your web service's API with the neat Smart Bear gadget, there are other ways. 
So all hope is not lost!

### TL;DR

---
    curl --header "content-type: text/xml" -d @request.xml http://sandwich:8400/computer-service
---

If you are not familiar with SOAP or want a quick refresher here is a snippet from wikipedia:

>SOAP (originally Simple Object Access Protocol) is a protocol specification for exchanging structured information 
in the implementation of web services in computer networks. 
...
It uses XML Information Set for its message format, 
and relies on application layer protocols, most often Hypertext Transfer Protocol (HTTP)
...
    
This means that most SOAP services transmit messages via HTTP post. 
A tool that is able to create and receive HTTP requests should fit the bill.

Unix's command line with the curl command (already or able to be installed) will be than sufficient tool.

If you do not have _curl_ on you machine, all you have to do (assuming you have sudo permission) is run:

    sudo apt-get install curl

The curl command manual states:

>curl  is  a  tool to transfer data from or to a server, using one of the supported protocols (DICT, FILE, FTP,
FTPS, GOPHER, HTTP, HTTPS, IMAP, IMAPS, LDAP, LDAPS, POP3, POP3S, RTMP, RTSP,  SCP,  SFTP,  SMB,  SMBS,  SMTP,
SMTPS, TELNET and TFTP).
       
Well look at that, it sure does fit the bill perfectly! 
    
Before going any further, I have provided a sample Spring Boot web service that will be referenced for the rest of the post.

It can be found on git hub here:

[https://github.com/cyclic-reference/web-service-sample](https://github.com/cyclic-reference/web-service-sample)

To run the sample you will need:
 - Internet Connection (At least the first time it is run)
 - [Java 8 runtime](http://www.oracle.com/technetwork/java/javase/downloads/index.html)
 - [Gradle 2.3+ ](https://gradle.org/install)
 
Once the repository is on your machine, in order to boot up the server do the following.

1. Open up a command window and make the current working directory the root of the web-service-sample repository
1. Run the command

        ./gradlew bootRun
    
Now there is a server running on your `localhost:8400` provided you did not have a process running on port 8400 before you started the server.

Most web services I have interacted with involve me creating a request from the defined schema and sending them to the web service.
The act of sending a request has almost always been in the from of an HTTP POST request.
This can be determined just by looking the headers of a SOAP request. Here is a sample: 

    POST http://sandwich:8400/computer-service HTTP/1.1 
    Accept-Encoding: gzip,deflate
    Content-Type: text/xml;charset=UTF-8
    SOAPAction: ""
    Content-Length: 312
    Host: sandwich:8400
    Connection: Keep-Alive
    User-Agent: Apache-HttpClient/4.1.1 (java 1.5)

There is quite a bit going on there, but the important bits will be highlighted.
The first line denotes that a POST request was sent to a server with a endpoint of:
    
    http://sandwich:8400/computer-service 

Where sandwich is the hostname of the server the web service is hosted on (sandwich happens to be the name of my local host).

The format of the content that the client is expecting from the server is XML. 
Which is denoted by:

    Content-Type: text/xml;charset=UTF-8

The example service does have methods with and without SOAPAction associated with it. 
In the headers, this was denoted by `SOAPAction: ""`. 
This bit is important, because if the method you try to call has a SOAP action associated with it then that changes the command needed to run.

Lastly, the web service definition, for the sample project, is a follows:

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

Now that a definition is present, a request can be created. Which should look a little like this:

{% highlight xml  %}
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                  xmlns:web="http://acari.io/simple/web-service">
   <soapenv:Header/>
   <soapenv:Body>
      <web:allComputersRequest/>
   </soapenv:Body>
</soapenv:Envelope>
{% endhighlight %}

This can be saved into a file called request.xml. 
It does not have to be called that, but the proper file name will have to be referenced in the command.
Keep that in mind when creating the file.

Now everything that is needed to create a _curl_ command to make a SOAP request is present!

The command should look like this:

    curl --header "content-type: text/xml" -d @request.xml http://sandwich:8400/computer-service

Time for a breakdown:

- `--header "content-type: text/xml"` tells the server that the client will only accept xml as a response.
- `-d @request.xml` -d is the argument for an HTTP POST request and @request.xml tells curl to use the file request.xml in the current working directory.
- `http://sandwich:8400/computer-service` is the URL of the deployed web service.

>Replacing _sandwich_ for the server hosting the (if you are running it on your machine use `localhost`) sample application. 

Running the command (provided you have change the url to the fully qualified path to the sample web service and have request.xml in the current working) will output this blob to the command line:

{% highlight xml  %}
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"><SOAP-ENV:Header/><SOAP-ENV:Body><ns2:allComputersResponse xmlns:ns2="http://acari.io/simple/web-service"><ns2:computers><ns2:model>Blade</ns2:model><ns2:subModel>Pro</ns2:subModel><ns2:ram>16</ns2:ram><ns2:make>Razer</ns2:make><ns2:cores>FOUR</ns2:cores></ns2:computers><ns2:computers><ns2:model>Macbook</ns2:model><ns2:subModel>Pro</ns2:subModel><ns2:ram>16</ns2:ram><ns2:make>Apple</ns2:make><ns2:cores>EIGHT</ns2:cores></ns2:computers><ns2:computers><ns2:model>XPS</ns2:model><ns2:subModel>13</ns2:subModel><ns2:ram>8</ns2:ram><ns2:make>Dell</ns2:make><ns2:cores>TWO</ns2:cores></ns2:computers><ns2:computers><ns2:model>Macbook</ns2:model><ns2:subModel>Air</ns2:subModel><ns2:ram>8</ns2:ram><ns2:make>Apple</ns2:make><ns2:cores>FOUR</ns2:cores></ns2:computers><ns2:computers><ns2:model>Blade</ns2:model><ns2:subModel>Stealth</ns2:subModel><ns2:ram>16</ns2:ram><ns2:make>Razer</ns2:make><ns2:cores>TWO</ns2:cores></ns2:computers></ns2:allComputersResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>
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
      <ns2:allComputersResponse xmlns:ns2="http://acari.io/simple/web-service">
         <ns2:computers>
            <ns2:model>Blade</ns2:model>
            <ns2:subModel>Pro</ns2:subModel>
            <ns2:ram>16</ns2:ram>
            <ns2:make>Razer</ns2:make>
            <ns2:cores>FOUR</ns2:cores>
         </ns2:computers>
         <ns2:computers>
            <ns2:model>Macbook</ns2:model>
            <ns2:subModel>Pro</ns2:subModel>
            <ns2:ram>16</ns2:ram>
            <ns2:make>Apple</ns2:make>
            <ns2:cores>EIGHT</ns2:cores>
         </ns2:computers>
         <ns2:computers>
            <ns2:model>XPS</ns2:model>
            <ns2:subModel>13</ns2:subModel>
            <ns2:ram>8</ns2:ram>
            <ns2:make>Dell</ns2:make>
            <ns2:cores>TWO</ns2:cores>
         </ns2:computers>
         <ns2:computers>
            <ns2:model>Macbook</ns2:model>
            <ns2:subModel>Air</ns2:subModel>
            <ns2:ram>8</ns2:ram>
            <ns2:make>Apple</ns2:make>
            <ns2:cores>FOUR</ns2:cores>
         </ns2:computers>
         <ns2:computers>
            <ns2:model>Blade</ns2:model>
            <ns2:subModel>Stealth</ns2:subModel>
            <ns2:ram>16</ns2:ram>
            <ns2:make>Razer</ns2:make>
            <ns2:cores>TWO</ns2:cores>
         </ns2:computers>
      </ns2:allComputersResponse>
   </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
{% endhighlight %}

So lets say that a file cannot be used as the data, that is no problem. 
A really long string can be used in place of `@request.xml`. 
Which basically is the contents of request.xml but with all of the `'\n'` characters removed.

`request.xml` with no newlines:
{% highlight xml  %}
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:web="http://acari.io/simple/web-service"><soapenv:Header/><soapenv:Body><web:allComputersRequest/></soapenv:Body></soapenv:Envelope>
{% endhighlight %}

Using the really long string instead of the file can be done as such:

    curl --header "content-type: text/xml" -d '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:web="http://acari.io/simple/web-service"><soapenv:Header/><soapenv:Body><web:allComputersRequest/></soapenv:Body></soapenv:Envelope>' http://sandwich:8400/computer-service | xml_pp
    
Thats all which is needed to accomplish a SOAP request for a method with no soap action.
When it comes time to invoke a method with a SOAP action, the only thing that needs to be added is a piece to the header.
The `computersByModel` method of the computer service has a SOAP action of:

    http://acari.io/simple/web-service/computersByModel

Here is a header sample from a SOAP request to the `computersByModel` method:

    POST http://sandwich:8400/computer-service HTTP/1.1
    Accept-Encoding: gzip,deflate
    Content-Type: text/xml;charset=UTF-8
    SOAPAction: "http://acari.io/simple/web-service/computersByModel"
    Content-Length: 312
    Host: sandwich:8400
    Connection: Keep-Alive
    User-Agent: Apache-HttpClient/4.1.1 (java 1.5)
 
A request to the `computersByModel` can be derived from the WSDL provided above.
Which should look something like this:

{% highlight xml  %}
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" 
                  xmlns:web="http://acari.io/simple/web-service">
   <soapenv:Header/>
   <soapenv:Body>
      <web:computersByModelRequest>
         <web:model>Blade</web:model>
      </web:computersByModelRequest>
   </soapenv:Body>
</soapenv:Envelope>
{% endhighlight %}

This can be saved into a file called request_soap_action.xml. 
Again, it does not have to be called that, but the proper file name will have to be referenced in the command.

    curl --header "content-type: text/xml" --header 'SOAPAction: "http://acari.io/simple/web-service/computersByModel"' -d @request_soap_action.xml http://sandwich:8400/computer-service | xml_pp

This outputs:

{% highlight xml  %}
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
   <SOAP-ENV:Header/>
   <SOAP-ENV:Body>
      <ns2:computersByModelResponse xmlns:ns2="http://acari.io/simple/web-service">
         <ns2:computers>
            <ns2:model>Blade</ns2:model>
            <ns2:subModel>Pro</ns2:subModel>
            <ns2:ram>16</ns2:ram>
            <ns2:make>Razer</ns2:make>
            <ns2:cores>FOUR</ns2:cores>
         </ns2:computers>
         <ns2:computers>
            <ns2:model>Blade</ns2:model>
            <ns2:subModel>Stealth</ns2:subModel>
            <ns2:ram>16</ns2:ram>
            <ns2:make>Razer</ns2:make>
            <ns2:cores>TWO</ns2:cores>
         </ns2:computers>
      </ns2:computersByModelResponse>
   </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
{% endhighlight %}

You should now be armed, dangerous, and able to make command line SOAP requests.

Thank you for your attention, I hope this helped!

-Alex
    
#### Resources:

- [http://spring.io/guides/gs/producing-web-service/](http://spring.io/guides/gs/producing-web-service/)