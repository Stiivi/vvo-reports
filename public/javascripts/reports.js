var update_search_form = function(){
  var disabled = false
  $("form.reports-search div.results").each(function(){
    if($(this).find('input[type=radio]').length > 0 && $(this).find('input[type=radio]:checked').length == 0) {
      disabled = true
    }
  })
  $("form.reports-search input.show-report-button").attr('disabled', disabled)
}

$(document).ready(function(){
  $("form.reports-search input.show-report-button").live('click', function(){
    var form = $(this).parents("form:first");
    form.find("input.show-report").val('true');
    var year = form.find("select#report_date_year").val();
    var month = form.find("select#report_date_month").val();
    var date_path = ''
    if(year) {
      date_path = year + "-" + month;
    }
    form.find("select#report_date_year").val('').attr('name', 'date_year')
    form.find("select#report_date_month").val('').attr('name', 'date_month')
    form.find("input#report_date_path").val(date_path).attr('name', 'report[date]')
    // form.submit();
  });
  
  $("form.reports-search input.repeat-search-button").live('click', function(){
    $(this).parents('form:first').find('div.results input[type=radio]').attr('checked', false)
  })
  
  update_search_form()
  $("form.reports-search div.results input[type=radio]").live('change', update_search_form)
  
  $("div.results a.show-results").live('click', function(){
    $(this).parents("div.results:first").find("div.result").removeClass('hidden')
    $(this).hide();
    return false;
  })
  
  $("a.fancybox").click(function(){
    $.fancybox.showActivity();
  })
  $("form.fancybox").live('submit', function(){
    $(this).addClass("ajax")
    $.fancybox.showActivity();
    $(this).submit()
    return false
  });
  
  
  Autosubmit.setup();
});

/** Autosubmit **/
var Autosubmit = function(){};
Autosubmit.setup = function() {
  var autosubmitTimeout = null;
  $("form.autosubmit input").live('keyup', function(){
    var trigger = this;
    var form = $(this).parents("form:first");
    clearTimeout(autosubmitTimeout);
    autosubmitTimeout = setTimeout(function(){
      $(trigger).addClass("loading");
      Autosubmit.submit(form, trigger);
    }, 500);
  });
};
Autosubmit.submit = function(form, trigger){
  var path = $(form).attr("action");
  var method = $(form).attr("method");
  $(trigger).parents("div:first").find('div.results input[type=radio]').attr('checked', false)
  var data = $(form).serialize();
  data += "&dimension=" + $(trigger).attr('data-dimension');
  $.ajax({
    type: method,
    url: path,
    dataType: 'script',
    data: data,
    complete: function(){
      $(trigger).removeClass("loading");
      update_search_form();
    }
  })
}