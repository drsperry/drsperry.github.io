if (window.innerWidth < 768) {
	$('[data-bss-disabled-mobile]').removeClass('animated').removeAttr('data-aos data-bss-hover-animate data-bss-parallax-bg data-bss-scroll-zoom');
}

$(document).ready(function(){

	$('[data-bss-hover-animate]')
		.mouseenter( function(){ var elem = $(this); elem.addClass('animated ' + elem.attr('data-bss-hover-animate')) })
		.mouseleave( function(){ var elem = $(this); elem.removeClass('animated ' + elem.attr('data-bss-hover-animate')) });
	$('[data-bss-tooltip]').tooltip();
});