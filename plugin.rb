# name: recommendation-plugin
# about: A plugin for providing recommendations to users
# version: 0.1
# authors: QBurst
# url: https://github.com/Jithin-K-M/recommendation-system


enabled_site_setting :recommendation_enable
PLUGIN_NAME = "discourse_recommendations".freeze
register_asset "stylesheets/recommendations.css"

after_initialize do
  load File.expand_path('../app/jobs/scheduled_sync_job.rb', __FILE__)
  load File.expand_path('../lib/recommendation_server.rb', __FILE__)
  load File.expand_path('../app/models/pluginprofile.rb', __FILE__)
  module ::DiscourseRecommendation

    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace DiscourseRecommendation
    end

  end

  require_dependency "application_controller"
  require_dependency "topic"
  require_dependency "post"
  class DiscourseRecommendation::AnswerController < ::ApplicationController

    def get_topics
      result_array = []
      if params['topics']
        begin
          tid = params["topics"].split(",").map(&:to_i)
          tid.each { |topic_id|
            begin
              result = Topic.find(topic_id)
              result_array.push({id: result.id, title: result.title, slug: result.slug})
            rescue
              # Add logs to log file
              p "Error on topic id " + String(topic_id)
            end
          }
        rescue
          p 'Error occurred'
        end
      end
      if result_array.length === 0
        render json: {success: false, result: result_array}
      else
        render json: {success: true, result: result_array}
      end

    end
  end

  DiscourseRecommendation::Engine.routes.draw do
    get "/gettopics" => "answer#get_topics"
  end

  if Pluginprofile::RecommendationMeta.get_env_key===nil
    register_data=RecommendationServer::Server.post('/activate-plugin', {"mode": "activation","env": "#{Rails.env}"})
    Pluginprofile::RecommendationMeta.add_key(register_data['key'].to_s)
    Pluginprofile::RecommendationMeta.set_sync_offset(0)
    Pluginprofile::RecommendationMeta.set_sync_status(false)
  end

  Pluginprofile::Config.create_config_file

  Discourse::Application.routes.append do
    # The  prefix is to differentiate plugin's call from other api calls.
    mount ::DiscourseRecommendation::Engine, at: "recommender"
  end

  DiscourseEvent.on(:post_created) do |*params|
    begin
      content = ""
      topic_id = params[0].topic_id
      topic = Topic.find(topic_id)
      posts_count = topic.posts_count
      for post_index in 1..posts_count
        post = Post.where(topic_id: topic_id, post_number: post_index)[0]
        content << post.cooked
      end
      key = Pluginprofile::RecommendationMeta.get_env_key()
      post_data = {
        "title": topic.title,
        "category": topic.category_id,
        "article_id": topic.id,
        "content": content,
        "key": key,
        "env": "#{Rails.env}"
      }
      RecommendationServer::Server.post('/publish-post', post_data)
    rescue
      p "No topic with id " + String(topic_id)
    end
  end

  DiscourseEvent.on(:post_deleted) do |*params|
    begin
      p "Post deleted"
      p params[0]
    rescue
      p "Error in post delete"
    end
  end
end
