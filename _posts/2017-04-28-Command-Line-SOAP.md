---
layout: post
title:  "SOAP Requests without SoapUI"
date:   2017-4-28
categories: soap
---

There are times when one might be unable to obtain access to SoapUI to help debug/test a deployed SOAP web service.
While it is vastly easier to interact with your web service's API with the neat Smart Bear gadget, all hope is not lost!

For Instance, access to a Unix's command line with the curl command already or able to be installed is a work around.
Curl's manual states:

       curl  is  a  tool to transfer data from or to a server, using one of the supported protocols (DICT, FILE, FTP,
       FTPS, GOPHER, HTTP, HTTPS, IMAP, IMAPS, LDAP, LDAPS, POP3, POP3S, RTMP, RTSP,  SCP,  SFTP,  SMB,  SMBS,  SMTP,
       SMTPS, TELNET and TFTP).
       
Well look at that, it handles HTTP requests! 
If you are not familiar with SOAP or want a quick refresher here is a snippet from wikipedia

    SOAP (originally Simple Object Access Protocol) is a protocol specification for exchanging structured information 
    in the implementation of web services in computer networks. 
    ...
    It uses XML Information Set for its message format, 
    and relies on application layer protocols, most often Hypertext Transfer Protocol (HTTP)

Most web services I have interacted with involve me creating a request from the defined schema and sending them to the web service.
The act of sending a request has almost always been in the from of an HTTP POST request.
This can be determined just by looking at a raw request from any SoapUI project. Here is a sample: 

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


