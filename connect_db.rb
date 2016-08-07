#!/usr/bin/env ruby
# encoding: utf-8
require 'sqlite3'
require 'active_record'

ActiveRecord::Base.establish_connection(
   :adapter   => 'sqlite3',
   :database  => 'passeio.db'
)
