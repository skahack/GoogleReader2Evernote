# -*- coding: utf-8 -*-
$:.unshift(File.dirname(__FILE__))

require 'uri'

require 'lib/sync'

UNSAFE = /[^-_.!~*()a-zA-Z\d]/

USER = 'example@mail.com'
PASS = 'password'


sync = GoogleReaderToEvernote::Sync.new USER, PASS

sync.limit_time 2 #week(s) ago

#sync.import URI.encode("user/-/state/com.google/starred", UNSAFE), ['[starred]']
#sync.import 'user%2F-%2Flabel%2FclipToEvernote', ['[clipToEvernote]', '[GoogleReader]']
#sync.import URI.encode('user/-/label/はてブ', UNSAFE), ['[はてブ]']
