'use strict';
var toggle_theme = document.getElementById('toggle_theme');
toggle_theme.href = 'javascript:void(0)';

const STORAGE_KEY_THEME = 'dark_mode';
const THEME_DARK = 'dark';
const THEME_LIGHT = 'light';

// TODO: theme state controlled by system
toggle_theme.addEventListener('click', function () {
    // Named themes build on a light or dark scheme, so ask the page instead of the stored value
    const isDarkTheme = document.body.classList.contains('dark-theme');
    const newTheme = isDarkTheme ? THEME_LIGHT : THEME_DARK;
    setTheme(newTheme);
    helpers.storage.set(STORAGE_KEY_THEME, newTheme);
    helpers.xhr('GET', '/toggle_theme?redirect=false', {}, {});
});

/** @param {THEME_DARK|THEME_LIGHT} theme */
function setTheme(theme) {
    // By default body element has .no-theme class that uses OS theme via CSS @media rules
    // It rewrites using hard className below
    if (theme === THEME_DARK) {
        toggle_theme.children[0].className = 'icon ion-ios-sunny';
        document.body.className = 'dark-theme';
    } else if (theme === THEME_LIGHT) {
        toggle_theme.children[0].className = 'icon ion-ios-moon';
        document.body.className = 'light-theme';
    } else {
        document.body.className = 'no-theme';
    }
}

/** @param {string} theme */
function isNamedTheme(theme) {
    return !!theme && theme !== THEME_DARK && theme !== THEME_LIGHT;
}

// Handles theme change event caused by other tab
addEventListener('storage', function (e) {
    if (e.key === STORAGE_KEY_THEME) {
        const theme = helpers.storage.get(STORAGE_KEY_THEME);
        if (!isNamedTheme(theme)) {
            setTheme(theme);
        } else if (!new URLSearchParams(location.search).has('dark_mode')) {
            // Named themes need their stylesheet and body classes from the server.
            // Pages with ?dark_mode= keep their theme, so two such tabs can't reload each other forever
            location.reload();
        }
    }
});

// Set theme from preferences on page load
addEventListener('DOMContentLoaded', function () {
    const prefTheme = document.getElementById('dark_mode_pref').textContent;
    if (prefTheme) {
        // Named themes keep their server-rendered body classes
        if (!isNamedTheme(prefTheme)) setTheme(prefTheme);
        helpers.storage.set(STORAGE_KEY_THEME, prefTheme);
    }
});
