$(document).ready(function(){
  $("form.reports-search input.show-report-button").click(function(){
    var form = $(this).parents("form:first");
    form.find("input.show-report").val('true');
    // form.submit();
  });
  
  $("form.reports-search input.repeat-search-button").click(function(){
    $(this).parents('form:first').find('div.results input[type=radio]').attr('checked', false)
  })
  
  var update_search_form = function(){
    var disabled = false
    $("form.reports-search div.results").each(function(){
      if($(this).find('input[type=radio]').length > 0 && $(this).find('input[type=radio]:checked').length == 0) {
        disabled = true
      }
    })
    $("form.reports-search input.show-report-button").attr('disabled', disabled)
  }
  
  update_search_form()
  $("form.reports-search div.results input[type=radio]").click(update_search_form)
});