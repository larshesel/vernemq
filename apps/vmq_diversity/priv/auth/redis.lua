-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- Redis Configuration, read the documentation below to properly
-- provision your database.
HOST = "127.0.0.1"
PORT = 6379
PASSWORD = ""
DATABASE = 0


-- In order to use this Lua plugin you must store a JSON Object containing 
-- the following properties as Redis Value:
--
--  - passhash: STRING (bcrypt)
--  - publish_acl: [STRING]  (Array of Strings)
--  - subscribe_acl: [STRING]  (Array of Strings)
--
-- 	The JSON array passed as publish/subscribe ACL contains the topic patterns
-- 	allowed for this particular user. MQTT wildcards as well as the variable 
-- 	substitution for %m (mountpoint), %c (client_id), %u (username) are allowed
-- 	inside a pattern. 
--
-- The Redis Key is the JSON Array [mountpoint, client_id, username]
-- 
-- IF YOU USE THE KEY/VALUE SCHEMA PROVIDED ABOVE NOTHING HAS TO BE CHANGED 
-- IN THE FOLLOWING SCRIPT.
function auth_on_register(reg)
    if reg.username ~= nil and reg.password ~= nil then
        key = json.encode({reg.mountpoint, reg.client_id, reg.username})
        res = redis.cmd(pool, "get " .. key)
        if res then
            print(res)
            res = json.decode(res)
            if res.passhash == bcrypt.hashpw(reg.password, res.passhash) then
                auth_cache.insert(
                    reg.mountpoint, 
                    reg.client_id, 
                    reg.username,
                    res.publish_acl,
                    res.subscribe_acl
                    )
                return true
            end
        end
    end
    return false
end

function auth_on_publish(pub)
    return false
end

function auth_on_subscribe(sub)
    return false
end

function on_client_gone(c)
end

function on_client_offline(c)
end

pool = "auth_mongodb"
config = {
    pool_id = pool,
    login = USER,
    password = PASSWORD,
    database = DATABASE,
    host = HOST,
    port = PORT
}

mongodb.ensure_pool(config)
hooks = {
    auth_on_register = auth_on_register,
    auth_on_publish = auth_on_publish,
    auth_on_subscribe = auth_on_subscribe,
    on_client_gone = on_client_gone,
    on_client_offline = on_client_offline
}


