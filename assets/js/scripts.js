$('.videoModal').on('hide.bs.modal', function(e) {
    var $if = $(e.delegateTarget).find('iframe');
    var src = $if.attr("src");
    $if.attr("src", '/empty.html');
    $if.attr("src", src);
});


$(window).scroll(function(){
    $(".celebratingbanner").css("opacity", 1 - $(window).scrollTop() / 50);
  });
