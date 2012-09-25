#
# Settings
#

# Paths
set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'

# link_to always generate relative link
set :relative_links, true

# Markdown
set :markdown_engine, :redcarpet
set :markdown, :fenced_code_blocks => true,
               :autolink => true, 
               :smartypants => true

#
# Page options, layouts, aliases and proxies
#

# Per-page layout changes:
#
# With no layout
# page "/path/to/file.html", :layout => false
#
# With alternative layout
# page "/path/to/file.html", :layout => :otherlayout
#
# A path which all have the same layout
# with_layout :admin do
#   page "/admin/*"
# end

# Proxy (fake) files
# page "/this-page-has-no-template.html", :proxy => "/template-file.html" do
#   @which_fake_page = "Rendering a fake page with a variable"
# end

#
# Helpers
#

# Automatic image dimensions on image_tag helper
# activate :automatic_image_sizes

#
# Build-specific configuration
#
configure :build do

  # Use relative URLs
  activate :relative_assets

  # Compress PNGs after build
  # First: gem install middleman-smusher
  # require "middleman-smusher"
  # activate :smusher
end

#
# Deploy via rsync
#
activate :deploy do |deploy|
  deploy.method = :rsync
  deploy.user = "jirutjak"
  deploy.host = "gitlab.fit.cvut.cz"
  deploy.path = "/opt/gitlab/gitlab/public/about"
  deploy.clean = true
end

