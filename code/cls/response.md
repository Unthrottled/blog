---
layout: post
---


SOAP Response
---


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
