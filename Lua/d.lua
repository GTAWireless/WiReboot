local moduleName = ...
local M = {}
_G[moduleName] = M

-- url="http://ota.wireboot.com/cm/"
function M.g(url,f,c)
  tf,hex=nil,nil

  http.get(url, nil, function(code, data)
    if (code<0) then
        return
    else
        tf='_'..f
        file.open(tf,"w") --temp file
        file.write(data)
        file.close()
        data=nil
        
        hex=crypto.toHex(crypto.fhash("md5",tf))

        if c~=nil then
           node.input(c)
        end

        tmr.alarm(3,500,0,function()
            --print(tf,hex)
              http.get(url..'.md5', nil, function(code, data)
                if (code<0) then
                    --print('err:md5')
                    return
                else
                    --print(hex,data)
                    if data==hex then
                      file.remove(f)
                      file.rename(tf,f)
                    end
                    data=nil
                end
            end)
            -- collectgarbage() 
          end)

    end
  end)
  
  --tmr.alarm(5,2000,0,function() sk:close() sk=nil strPost = nil file.close() collectgarbage() end)
end

return M
