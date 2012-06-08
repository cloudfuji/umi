window.onload = function(){
    if(!$('body').hasClass('video')){
	$('body').css('background', '#FFF !important');
    }
};

$(function(){
    var rpc = window.parent.rpc;

    if(typeof window.parent.rpc != 'undefined'){
	$('#launch').click(function(e){
	    e.preventDefault();
	    console.log(window.parent.rpc);
	    window.parent.rpc.launchModal($(this).attr('href'));
	    return false;
	});
    }

});
