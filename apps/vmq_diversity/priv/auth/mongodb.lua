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

-- MongoDB Configuration, read the documentation below to properly
-- provision your database.
HOST = "127.0.0.1"
PORT = 27017
COLLECTION = "vmq_acl_auth"
USER = nil
PASSWORD = nil
DATABASE = nil


-- In order to use this Lua plugin your MongoDB docs used for authentication 
-- and authorization must contain the following properties:
--
--  - mountpoint: STRING
--  - client_id: STRING
--  - username: STRING
--  - passhash: STRING (bcrypt)
--  - publish_acl: [STRING]  (Array of Strings)
--  - subscribe_acl: [STRING]  (Array of Strings)
--
-- 	The BSON array passed as publish/subscribe ACL contains the topic patterns
-- 	allowed for this particular user. MQTT wildcards as well as the variable 
-- 	substitution for %m (mountpoint), %c (client_id), %u (username) are allowed
-- 	inside a pattern. 
-- 
-- IF YOU USE THE DOCUMENT SCHEMA PROVIDED ABOVE NOTHING HAS TO BE CHANGED IN THE
-- FOLLOWING SCRIPT.
function auth_on_register(reg)
    if reg.username ~= nil and reg.password ~= nil then
        doc = mongodb.find_one(pool, COLLECTION, 
                                {mountpoint = reg.mountpoint,
                                 client_id = reg.client_id,
                                 username = reg.username})
        if doc ~= false then
            if doc.passhash == bcrypt.hashpw(reg.password, doc.passhash) then
                auth_cache.insert(
                    reg.mountpoint, 
                    reg.client_id, 
                    reg.username,
                    doc.publish_acl,
                    doc.subscribe_acl
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

