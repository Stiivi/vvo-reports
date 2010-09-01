// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$(document).ready(function(){
  $("form.date-picker").each(function(i, form){
    var year = $(form).find("select.year");
    var month = $(form).find("select.month");
    
    var check_date_select = function(){
      if(year.val() == '') {
        month.val('');
        month.attr('disabled', true);
      }
      else {
        month.attr('disabled', false);
      }
    };
    
    check_date_select();
    
    year.change(check_date_select);
    month.change(check_date_select);
  });
  
  $("form.submit-on-change select").change(function(){
    $(this).parents("form:first").submit();
  });
  
  $("input.autofocus:first").focus();
});