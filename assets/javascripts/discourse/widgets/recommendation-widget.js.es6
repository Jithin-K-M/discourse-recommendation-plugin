import { createWidget } from 'discourse/widgets/widget';
import { getTopic } from 'discourse/plugins/recommendation-plugin/discourse/helpers/recommendations';
import {getCurrentPageJson} from 'discourse/plugins/recommendation-plugin/discourse/libs/ajax';
import {customAjax} from 'discourse/plugins/recommendation-plugin/discourse/libs/ajax';
import {handleError} from 'discourse/plugins/recommendation-plugin/discourse/libs/errorhandler';
import { ajax } from 'discourse/lib/ajax';
import { h } from 'virtual-dom';

export default createWidget('recommendation-widget', {
  tagName: 'div.recommended-topics',
  buildKey: () => 'recommendation-widget',
  defaultState() {
    return {
      loading: false,
      similar_topics: null,
      user_recommendations: null
    };
  },

  refreshRecommendations() {
    if (this.state.loading) {
      return;
    }
    this.state.loading = true;
    getCurrentPageJson()
      .then((pageInfo) => {
        var user_id = Discourse.User.currentProp("id");
        if (pageInfo.user_id != -1) {
          customAjax("/get-similar-articles", "POST", {
            user_id: user_id !== undefined ? user_id : 1,
            article_id: pageInfo.id
          }).then((json) => {
            getTopic(this, json.similar_articles).then((result) => {
              this.state.similar_topics = result;
              customAjax("/recommend-other-users-views", "POST", {
                user_id: user_id !== undefined ? user_id : 1,
                article_id: pageInfo.id
              }).then((json) => {
                getTopic(this, json.recommendations).then((result) => {
                  this.state.user_recommendations = result;
                  this.state.loading = false;
                  this.scheduleRerender()
                });
              }, (err) => {
                handleError(err);
              });
            });
          }, (reason) => {
            handleError(reason);
          });
        } else {
          this.state.similar_topics = [];
          this.state.user_recommendations = [];
          this.state.loading = false;
          this.scheduleRerender()
        }
      }, (err) => {
        handleError(err);
      });
  },

  html(attrs, state) {
    if (!state.similar_topics) {
      this.refreshRecommendations();
    }
    const result = [h('h2', 'Recommended for you')];
    if (state.loading == true) {
      result.push(h('div.spinner-container', h('div.spinner')));
    } else {
      result.push(h('h3', 'Similar Articles'));
      if (state.similar_topics.length > 0) {
        for (var index = 0; index < state.similar_topics.length; index++) {
          var topic = state.similar_topics[index];
          result.push(h('div.row', h('a', {href: '/t/' + topic.slug + '/' + topic.id}, topic.title)));
        }
      } else {
        result.push(h('div.row', 'No articles to show'));
      }
      result.push(h('h3', 'Users who viewed this also viewed'));
      if (state.user_recommendations.length > 0) {
        for (index = 0; index < state.user_recommendations.length; index++) {
          topic = state.user_recommendations[index];
          result.push(h('div.row', h('a', {href: '/t/' + topic.slug + '/' + topic.id}, topic.title)));
        }
      } else {
        result.push(h('div.row', 'No articles to show'));
      }
    }

    return result;
  }
});
