#!/bin/sh
export ROOT=$(cd `dirname $0`; pwd)

#$ROOT/skynet/3rd/lua/lua $ROOT/client/simpleclient.lua $ROOT $1
/home/shimingliang/lua-5.3.0/src/lua $ROOT/client/simpleclient.lua $ROOT $1
