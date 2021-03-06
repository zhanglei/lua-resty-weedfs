--author:medcl,m@medcl.net,http://log.medcl.net
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function file_exists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end

function exit_with_code(code)
--    ngx.say(code)
    ngx.exit(code)
    return
end

function req_orig_file(file_url)
    local http = require"resty.http"
    local hc = http:new()
    local ok, code, headers, status, body = hc:request{
        url = file_url,
        timeout = 3000,
    }

    if code ~= 200 then
       return exit_with_code(404)
    else
        if body == nil then
            return exit_with_code(404)
        else
            if (body..'a') == 'a' then
                return exit_with_code(404)
            else
                ngx.say(body)
                ngx.flush(true)
				exit_with_code(200)
                return
            end
        end
    end
end


function save_orig_file(file_url,local_file_folder,local_file_path)
    local http = require"resty.http"
    local hc = http:new()
    local ok, code, headers, status, body = hc:request{
        url = file_url,
        timeout = 3000,
    }

    if code ~= 200 then
        return exit_with_code(404)
    else
        if body == nil then
            return exit_with_code(404)
        else
            if (body..'a') == 'a' then
                return exit_with_code(404)
            else
                local mkdir_command ="mkdir "..local_file_folder.." -p >/dev/null 2>&1 "
                os.execute(mkdir_command)
                file = io.open(local_file_path, "w");
                if (file) then
                    file:write(body);
                    file:close();
                else
                    return exit_with_code(500)
                end
            end
        end
    end
end

function req_volume_server()
-- TODO,get from weedfs,curl http://localhost:9333/dir/lookup?volumeId=3
end


function process_img(file_volumn,file_id,file_size,file_url)
    local image_sizes = { "100x100", "80x80", "800x600", "40x40" ,"480x320","320x210","640x420"};
    local local_file_root =  ngx.var.local_img_fs_root .."images/";
    local local_file_in_folder = local_file_root .."orig/".. file_volumn .."/";
    local local_file_in_path = local_file_in_folder.. file_id ..".jpg";

    local local_file_out_folder = local_file_root.. file_size .."/" .. file_volumn .."/";
    local local_file_out_path = local_file_out_folder.. file_id ..".jpg";
    local local_file_out_rel_path = "/images/".. file_size .."/" .. file_volumn .."/".. file_id ..".jpg";


    if table.contains(image_sizes, file_size) then

        if(not file_exists(local_file_in_path))then
            save_orig_file(file_url,local_file_in_folder,local_file_in_path)
        end

        if(file_exists(local_file_in_path))then
            local mkdir_command ="mkdir "..local_file_out_folder.." -p >/dev/null 2>&1 "
            local convert_command = "gm convert " .. local_file_in_path .. " -thumbnail " .. file_size .. "^  -quality 50  -gravity center -extent " .. file_size .. " " .. local_file_out_path .. ">/dev/null 2>&1 ";
            os.execute(mkdir_command)
            os.execute(convert_command)
            if(file_exists(local_file_out_path))then
--                ngx.redirect(local_file_out_rel_path)
               local file = io.open(local_file_out_path, "r");
                if (file) then
                    local content= file:read("*a");
                    file:close();
                    ngx.say(content)
                    ngx.flush(true)
                else
                    return exit_with_code(500)
                end
            end
        end
    else
        return exit_with_code(404)
    end
end

function process_audio(file_volumn,file_id,file_size,file_url)

    local audio_sizes = { "mp3" };
    local local_file_root = ngx.var.local_audio_fs_root .."audios/";
    local local_file_in_folder = local_file_root .."orig/".. file_volumn .."/";
    local local_file_in_path = local_file_in_folder.. file_id ..".mp3";

    local local_file_out_folder = local_file_root.. file_size .."/" .. file_volumn .."/";
    local local_file_out_path = local_file_out_folder.. file_id ..".mp3";
    local local_file_out_rel_path = "/audios/".. file_size .."/" .. file_volumn .."/".. file_id ..".mp3";


    if table.contains(audio_sizes, file_size) then
        if(not file_exists(local_file_in_path))then
            save_orig_file(file_url,local_file_in_folder,local_file_in_path)
        end

        if(file_exists(local_file_in_path))then
            local mkdir_command ="mkdir "..local_file_out_folder.." -p >/dev/null 2>&1 "
            local convert_command = "ffmpeg -i " .. local_file_in_path .. " -ab 64 " .. local_file_out_path .. " >/dev/null 2>&1 ";
            os.execute(mkdir_command)
            os.execute(convert_command)
            if(file_exists(local_file_out_path))then
--                ngx.redirect(local_file_out_rel_path)
                local file = io.open(local_file_out_path, "r");
                if (file) then
                    local content= file:read("*a");
                    file:close();
                    ngx.say(content)
                    ngx.flush(true)
                else
                    return exit_with_code(500)
                end
            end
        end
    else
        return exit_with_code(404)
    end
end

local file_volumn = ngx.var.arg_volumn
local file_id = ngx.var.arg_id
local file_url = ngx.var.weed_img_root_url .. file_volumn .. "," .. file_id
local process_type = ngx.var.arg_type or "na";
local file_size = ngx.var.arg_size or "na";

if ngx.var.arg_size == nil or ngx.var.arg_volumn == nil or ngx.var.arg_id == nil then
    return exit_with_code(400)
elseif ngx.var.arg_size == "orig" then
    req_orig_file(file_url)
end

if(process_type == "img") then
    process_img(file_volumn,file_id,file_size,file_url)
elseif(process_type == "audio")then
    process_audio(file_volumn,file_id,file_size,file_url)
end
