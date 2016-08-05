srv=net.createServer(net.TCP)
srv:listen(80,function(conn)
   local okHeader= "HTTP/1.1 200 OK\r\nAccess-Control-Allow-Origin:*\r\n\r\n"
   local DataToGet = 0
   local sending=false

   function s_output(str)
      if(conn~=nil) then
        if(sending) then
            conn:send(str)
        else
            sending=true
            conn:send(okHeader..str)
        end
      end
   end

  node.output(s_output, 1)

  conn:on("receive",function(conn,payload)
     local pos=string.find(payload,"%c%-%-%-")

     --if pos==nil and fstart==nil then
     if pos==nil then
          print("ERR:"..payload)
          return
     end
     --print(string.sub(payload,pos+4))
     node.input(string.sub(payload,pos+4))
  end)

  conn:on("sent",function(conn)
    sending=false
    conn:close()
    --node.output(nil)
  end)
end)
print("free:", node.heap())
--print("IP:", wifi.sta.getip())
