source: http://wotblitz.eu/encyclopedia/vehicles/usa/

$('.vehicles-list_img').map(function(i, d) { return "<img src=\"http://wotblitz.eu/dcont/1.5.1.0/tankopedia/usa/" + $(d).attr('src').replace(/^.*[\\\/]/, '').replace("_preview", "") + "\">"; });