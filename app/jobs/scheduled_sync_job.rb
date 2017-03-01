load File.expand_path('../../../lib/recommendation_server.rb', __FILE__)
load File.expand_path('../../../app/models/pluginprofile.rb', __FILE__)

module RecommenderJobs
  require_dependency "topic"
  require_dependency "post"
  class SyncTopics < Jobs::Scheduled
    every 30.seconds

    def execute(args)

      if SiteSetting.daily_retrain_time != Pluginprofile::RecommendationMeta.get_retrial_time()
        p "Change detected"
        RecommendationServer::Server.post('/retrial-period',{"key": Pluginprofile::RecommendationMeta.get_env_key(),"period": SiteSetting.daily_retrain_time})
        Pluginprofile::RecommendationMeta.set_retrial_time(SiteSetting.daily_retrain_time)
      end
      
      if Pluginprofile::RecommendationMeta.get_sync_completed
        # p "Sync completed"
      else
        p "Syncing posts..."
        last_topic_id = Topic.last().id
        sync_completed = false
        post_data = []
        sync_offset = Pluginprofile::RecommendationMeta.get_sync_offset()
        next_offset = sync_offset + 20
        sync_offset += 1
        if next_offset > last_topic_id
          next_offset = last_topic_id
          sync_completed = true
        end
        for index in sync_offset..next_offset
          begin
            content = ""
            topic = Topic.find(index)
            if topic.user_id != -1
              posts_count = topic.posts_count
              for post_index in 1..posts_count
                post = Post.where(topic_id: index, post_number: post_index)[0]
                content << post.cooked
              end
              data = {:title => topic.title, :category => topic.category_id, :article_id => topic.id, :content => content}
              post_data.push(data)
            end
          rescue
            p "Syncing topics: No topic with id " + String(index)
          end
        end
        key = Pluginprofile::RecommendationMeta.get_env_key()
        scalar = {:data => post_data}
        RecommendationServer::Server.post('/sync-posts', {"scalar": scalar.to_json.to_s, "key": key, "env": "#{Rails.env}"})
        Pluginprofile::RecommendationMeta.set_sync_offset(next_offset)
        Pluginprofile::RecommendationMeta.set_sync_status(sync_completed)
      end
    end

  end
end
