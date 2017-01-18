import { ajax } from 'discourse/lib/ajax';

export function getTopic(context, id) {
	return ajax('/recommender/gettopics?topics=' + id).then((response) => {
		return response.result;
	}).catch(() => {
		console.log('getting topic failed');
		return '';
	})
}
