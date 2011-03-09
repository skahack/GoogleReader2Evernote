# -*- coding: utf-8 -*-

require 'rubygems'
require 'sqlite3'
require 'json'
require 'appscript'

require 'lib/googlereader'

module GoogleReaderToEvernote
  class Sync

    DB = 'manage.db'

    def initialize(user, pass)
      @sec = 60 * 60 * 24 * 7 * 2

      @reader = GoogleReaderToEvernote::GoogleReader.new user, pass
      @db = SQLite3::Database.new(File.dirname(__FILE__) + '/../' + DB, :results_as_hash => true)

      @reader.login

      create_manage_table unless exist_manage_table
    end

    def exist_manage_table
      count = @db.execute("SELECT count(*) FROM sqlite_master where type = 'table' and tbl_name = 'manage'")

      count[0][0] > 0
    end

    def get_limit_time
      time = Time.now - @sec

      (time.to_f * 1000).to_i
    end

    def limit_time(week)
      @sec = 60 * 60 * 24 * 7 * week
    end

    def create_manage_table
      sql = 'CREATE TABLE manage ( ' +
        'tag_name TEXT, ' +
        'latest_id TEXT ' +
        ')'
      @db.execute(sql)
    end

    def update_item(id, feed)
      count = @db.execute("SELECT count(*) FROM manage WHERE tag_name = '#{feed}'")
      if count[0][0] == 0
        @db.execute("INSERT INTO manage (tag_name, latest_id) VALUES ('#{feed}', '#{id}')")
      else
        @db.execute("UPDATE manage SET latest_id='#{id}' WHERE tag_name = '#{feed}'")
      end
    end

    def latest_id(feed)
      id = @db.execute("SELECT latest_id FROM manage WHERE tag_name = '#{feed}'")
      if id.empty?
        return ''
      else
        id[0]["latest_id"]
      end
    end


    def import(feed, tags = [], continuation = nil)
      if continuation == nil
        @latest_id = latest_id(feed)
      end

      evernote = Appscript.app('evernote')
      json = JSON.parse(@reader.feed_list(feed, continuation))

      json['items'].each do |item|
        id = item['id'] || ''
        href = item['alternate'][0]['href'] || ''
        title = item['title'] || ''
        crawltime = item['crawlTimeMsec'] || ''

        if continuation == nil
          update_item id, feed
        end

        return if id == @latest_id || crawltime.to_i < get_limit_time

        evernote.create_note(:title => title, :from_url => href, :tags => tags)
        puts "imported : #{title.delete("\n")}"
      end

      if json['continuation']
        import(feed, tags, json['continuation'])
      end
    end
  end
end

