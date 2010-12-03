// Fancybox preparation
// ********************************************************************
$(document).ready(function(){
  $("a.fancybox").click(function(){
    $.fancybox.showActivity();
  })
  $("form.fancybox").live('submit', function(){
    $(this).addClass("ajax")
    $.fancybox.showActivity();
  });
});

// Search form
// ********************************************************************

$(document).ready(function(){
  Autocomplete.setup();
  $("form.reports-search").live('submit', function(){
    var form = $(this);
    var year = form.find("select#report_date_year").val();
    var month = form.find("select#report_date_month").val();
    var date_path = ''
    if(year) {
      date_path = year + "-" + month;
    }
    form.find("select#report_date_year").val('').attr('name', 'date_year')
    form.find("select#report_date_month").val('').attr('name', 'date_month')
    form.find("input#report_date_path").val(date_path).attr('name', 'report[date]')
  })
});

// Class taking care of autocomplete stuff. [REFACTORME]
// ********************************************************************

var Autocomplete = function(){};
Autocomplete.setup = function() {
  var autocompleteTimeout = null;
  var trigger = $("form.autocomplete input");
  trigger.livequery(function(){
    var hiddenEl = Autocomplete.hidden_element_for_trigger($(this));
    if (hiddenEl.val()) {
      $(this).addClass("selected");
    }
  });
  trigger.live('focus', function(){
    Autocomplete.show(this);
  })
  trigger.live('blur', function(){
    Autocomplete.hide(this);
  })
  trigger.live('keyup', function(){
    trigger = this;
    Autocomplete.deselect_trigger(trigger);
    var form = $(this).parents("form:first");
    clearTimeout(autocompleteTimeout);
    autocompleteTimeout = setTimeout(function(){
      $(trigger).addClass("loading");
      Autocomplete.submit(form, trigger);
    }, 500);
  });
};
Autocomplete.submit = function(form, trigger){
  var path = $(form).attr('data-autocomplete-path');
  if(!path) {
    var path = $(form).attr("action");
  }
  var method = $(form).attr("method");
  $(trigger).parents("div:first").find('div.results input[type=radio]').attr('checked', false)
  var data = $(form).serialize();
  var dimension = $(trigger).attr('data-dimension');
  var autocomplete_element = Autocomplete.element_for_trigger(trigger);
  $.ajax({
    type: 'POST',
    url: path,
    dataType: 'json',
    data: data,
    success: function(data){
      $(trigger).removeClass("loading");
      var data_for_dimension = data[dimension];
      autocomplete_element.show().children().remove();
      for(match in data_for_dimension) {
        var match_data = data_for_dimension[match];
        var link = $("<a />").attr('href', '#').text(match_data.value);
        link.attr('data-path', match_data.path);
        link.click(function(){
          Autocomplete.select_trigger_with_match(trigger, $(this));
          return false;
        })
        autocomplete_element.append(link);
      }
    }
  })
};
Autocomplete.element_for_trigger = function(trigger){
  var dimension = $(trigger).attr('data-dimension');
  var autocomplete_element = $(".autocomplete."+dimension);
  return autocomplete_element;
};
Autocomplete.hidden_element_for_trigger = function(trigger){
  var dimension = $(trigger).attr('data-dimension');
  var hidden_element = $("input[type=hidden][data-dimension="+dimension+"]");
  return hidden_element;
};
Autocomplete.hide = function(trigger){
  setTimeout(function(){
    var autocomplete_element = Autocomplete.element_for_trigger(trigger);
    autocomplete_element.hide();
  }, 100);
};
Autocomplete.show = function(trigger){
  var autocomplete_element = Autocomplete.element_for_trigger(trigger);
  autocomplete_element.show();
};
Autocomplete.select_trigger_with_match = function(trigger, match){
  var autocomplete_element = Autocomplete.element_for_trigger(trigger);
  $(trigger).val(match.text());
  autocomplete_element.children().remove();
  autocomplete_element.hide();
  $(trigger).addClass('selected');
  var hidden_element = Autocomplete.hidden_element_for_trigger(trigger);
  var path = match.attr('data-path');
  hidden_element.val(path);
};
Autocomplete.deselect_trigger = function(trigger){
  $(trigger).removeClass('selected');
  var hidden_element = Autocomplete.hidden_element_for_trigger(trigger);
  hidden_element.val('');
}