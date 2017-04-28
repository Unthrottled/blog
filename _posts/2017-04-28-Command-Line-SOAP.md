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

