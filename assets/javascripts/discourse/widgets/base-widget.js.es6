import { createWidget } from 'discourse/widgets/widget';
import { h } from 'virtual-dom';

export default createWidget('base-widget', {
  tagName: 'div',

  html(attrs, state) {
    var self = this;
    const result = [];
    result.push(self.attach('recommendation-widget'));

    return result;
  }
});
