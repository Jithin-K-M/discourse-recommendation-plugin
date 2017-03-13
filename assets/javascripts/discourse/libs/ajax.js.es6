import {pluginData} from 'discourse/plugins/recommendation-plugin/discourse/config/config';
const serverUrl = "http://10.7.30.15:9000";

export function customAjax(api, method, params) {
  var pluginKey = pluginData();
  params.key = pluginKey.key.toString();
  params.env = pluginKey.env;
  let apiToHit;
  apiToHit = api ? api : "";
  return new Promise(function (resolve, reject) {
    getJSON(serverUrl + apiToHit, params, method).then(function (json) {
      if (typeof (json) === "string")
        resolve(JSON.parse(json));
      else
        resolve(json);
    }, function (reason) {
      reject(reason);
    });
  });

}

export function getCurrentPageJson() {
  let apitoHit = window.location.href + ".json";
  return new Promise((resolve, reject) => {
    getJSON(apitoHit, "", "GET").then((json) => {
      if (typeof (json) === "string")
        resolve(JSON.parse(json));
      else
        resolve(json);
    }, (error) => {
      reject(error)
    });
  });
}

function getJSON(url, params, method) {
  return new Promise(function (resolve, reject) {
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = handler;
    xhr.open(method, url);
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.setRequestHeader('Accept', 'application/json');
    if (params !== "" && method != "GET") {
      xhr.send(JSON.stringify(params));
    } else {
      xhr.send();
    }

    function handler() {
      if (xhr.readyState === 4) {
        if (xhr.status === 200) {
          resolve(this.response);
        } else {
          reject(new Error('getJSON: `' + url + '` failed with status: [' + xhr.status + ']'));
        }
      }
    }
  });

}
