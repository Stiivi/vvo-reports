namespace :search do
  task :index do
    system 'indexer --all --rotate --config config/sphinx.conf'
  end
  
  task :server do
    system 'searchd --config config/sphinx.conf'
  end
end