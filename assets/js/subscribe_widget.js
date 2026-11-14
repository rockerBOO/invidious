'use strict';
var subscribe_data = JSON.parse(document.getElementById('subscribe_data').textContent);
var payload = 'csrf_token=' + subscribe_data.csrf_token;

var subscribe_button = document.getElementById('subscribe');
// Handled here: don't submit the form (the no-JS fallback)
subscribe_button.type = 'button';

if (subscribe_button.getAttribute('data-type') === 'subscribe') {
    subscribe_button.onclick = subscribe;
} else {
    subscribe_button.onclick = unsubscribe;
}

function set_button_state(type) {
    var text = type === 'subscribe' ? subscribe_data.subscribe_text : subscribe_data.unsubscribe_text;
    subscribe_button.setAttribute('data-type', type);
    subscribe_button.onclick = type === 'subscribe' ? subscribe : unsubscribe;
    subscribe_button.innerHTML = '<b>' + text + ' | ' + subscribe_data.sub_count_text + '</b>';
}

function subscribe() {
    set_button_state('unsubscribe');

    var url = '/subscription_ajax?action=create_subscription_to_channel&redirect=false' +
        '&c=' + subscribe_data.ucid;

    helpers.xhr('POST', url, {payload: payload, retries: 5, entity_name: 'subscribe request'}, {
        onNon200: function (xhr) {
            set_button_state('subscribe');
        },
        onTotalFail: function () {
            set_button_state('subscribe');
        }
    });
}

function unsubscribe() {
    set_button_state('subscribe');

    var url = '/subscription_ajax?action=remove_subscriptions&redirect=false' +
        '&c=' + subscribe_data.ucid;

    helpers.xhr('POST', url, {payload: payload, retries: 5, entity_name: 'unsubscribe request'}, {
        onNon200: function (xhr) {
            set_button_state('unsubscribe');
        },
        onTotalFail: function () {
            set_button_state('unsubscribe');
        }
    });
}
