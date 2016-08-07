#!/usr/bin/env ruby
# encoding: utf-8
require './connect_db.rb'

ActiveRecord::Migration.class_eval do
  create_table :pages do |t|
    t.string :fb_id, null: false
    t.string :name, null: false
    t.integer :likes_count, null: false
    t.string :category
    t.boolean :visited
  end
  add_index :pages, :fb_id, unique: true

  create_table :likes, :id => false do |t|
    t.references :from, :null => false
    t.references :to, :null => false
  end
end
