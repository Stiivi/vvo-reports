$(document).ready(function(){
  $("form.reports-search input.repeat-search").click(function(){
    var form = $(this).parents("form:first");
    form.find("input.show-report").remove();
    form.find("input[type=radio]").attr('checked', false)
    form.submit();
  });
});