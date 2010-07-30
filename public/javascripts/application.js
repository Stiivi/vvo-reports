// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$(document).ready(function(){
  $("form.submit-on-change select").change(function(){
    $(this).parents("form:first").submit();
  })
});