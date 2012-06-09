// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs


    function scaleModal(){
	//for remote modal requests
	if(typeof window.parent.rpc != 'undefined'){
	    window.parent.rpc.resizeModal($main.outerWidth(), $main.innerHeight());
	}

	//for local modal requests
	if(typeof window.parent.$ != 'undefined'){
	    if(typeof window.parent.$.colorbox != 'undefined'){
		window.parent.$.colorbox.resize({
		    width: $main.outerWidth() 
		    ,height: $main.innerHeight()
		    ,scrolling: false
		});
	    }
	}
    };

$(function(){
  //
  //do some scaling magic for modals
  //
  if(window.location != window.parent.location){
    $main = $('#main');
        
    //best to have all the content loaded so we know the true height
    window.onload =  scaleModal;
    
    //if the dom gets expanded scale the modal again
    document.addEventListener("DOMNodeInserted", scaleModal);
      
  }
});
