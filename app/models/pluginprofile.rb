#Plugin registration and other stuffs goes here

require_dependency "plugin_store"

module Pluginprofile

  class RecommendationMeta
    def self.get_env_key()
      PluginStore.get('recommendation-plugin', "recommendation_key_#{Rails.env}")
    end

    def self.add_key(key)
      ::PluginStore.set("recommendation-plugin", "recommendation_key_#{Rails.env}", key)
    end

    def self.get_sync_completed()
      PluginStore.get('recommendation-plugin', "recommendation_syncstatus_#{Rails.env}")
    end

    def self.set_sync_status(status)
      ::PluginStore.set("recommendation-plugin", "recommendation_syncstatus_#{Rails.env}", status)
    end

    def self.get_sync_offset()
      PluginStore.get('recommendation-plugin', "recommendation_syncoffset_#{Rails.env}")
    end

    def self.set_sync_offset(offset)
      ::PluginStore.set("recommendation-plugin", "recommendation_syncoffset_#{Rails.env}", offset)
    end

  end

  class Config
    def self.create_config_file()
      p "Creating Config File"
      begin
        path =File.expand_path(File.join(File.dirname(__FILE__), "../../", "assets/javascripts/discourse/config/config.js.es6"))
        File.open(path, 'w+') { |f| f.write("export function pluginData() { return {\"key\":#{Pluginprofile::RecommendationMeta.get_env_key},\"env\":\"#{Rails.env}\"};}") }
      rescue Exception => e
        puts e.message
        puts e.backtrace.inspect
        p "Error Occurred in creating config file"
      end

    end
  end
end