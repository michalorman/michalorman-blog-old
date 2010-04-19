# -*- coding: utf-8 -*-
ROOT = 'blog'
BLOG_PATH = ROOT + '/'
POSTS_DIR = '_posts'
INCLUDES_PATH = '_includes/'
CATEGORIES = INCLUDES_PATH + 'categories.html'
SITEMAP = 'sitemap.xml'

class Category
  require "rubygems"
  require "jekyll"
  
  include Jekyll::Filters
  include FileUtils
  
  attr_reader :name, :posts_path
  
  def initialize(name)
    @name = name
    @dir = BLOG_PATH + @name + "/";
    @posts_path = @dir + POSTS_DIR
  end
  
  def exists?
    File.exists?(BLOG_PATH + @name)
  end
  
  def create
    unless exists?
      puts "creating new category: #@name"
      mkdir_p(@posts_path, :verbose => false)
      File.open(@dir + 'index.markdown', 'w+') do |file|
        file.puts index_content
      end
    end
  end
  
private
  
  def index_content
    <<-END
---
layout: default
title: Michał Orman - 
description: Posty w kategorii 
keywords:
navbar_pos: 1
---
# Posty w kategorii 
{% assign category = site.categories.#@name %}{% include post-link.html %}
    END
  end
  
end

class Post
  attr_reader :post_path
  
  def initialize(name, category_name)
    @name = create_name(name)
    @category = Category.new(category_name)
    @post_path = @category.posts_path + "/#@name"
  end
  
  def exists?
    File.exists?(@post_path)
  end
  
  def create
    unless exists?
      @category.create unless @category.exists?
      puts "creating new post: #@name"
      File.open(@post_path, 'w+') do |file|
        file.puts default_content
      end
    end
  end
  
private

  def create_name(name)
    Time.now.strftime('%Y-%m-%d-') + name + '.markdown'
  end

  def default_content
    <<-END
---
layout: post
title: 
description: 
keywords: 
navbar_pos: 1
---
    END
  end
end

class Archive
  def initialize(month, year)
    @month = month
    @year = year
    @year_path = BLOG_PATH + "/#@year"
    @path = @year_path + "/#@month"
  end
  
  def exists?
    File.exists?(@path)
  end
  
  def year_path_exists?
    File.exists?(@year_path)
  end
  
  def create
    unless exists?
      puts "creating archive: #@month/#@year"
      unless year_path_exists?
        mkdir @year_path, :verbose => false
        File.open(@year_path + '/index.markdown', 'w+') do |file|
          file.puts year_index_content
        end
      end
      mkdir_p @path, :verbose => false
      File.open(@path + '/index.markdown', 'w+') do |file|
        file.puts archive_content
      end
    end
  end
  
private

  def year_index_content
    <<-END
---
layout: default
title: Archiwum @#year
description: Posty z roku #@year
navbar_pos: 1
---
{% assign year = '#@year' %}{% include archive-year.html %}
    END
  end
  
  def archive_content
    <<-END
---
layout: default
title: Archiwum #@month/#@year
description: Posty z miesiąca #@month/#@year
navbar_pos: 1
---
{% assign month = '#@month/#@year' %}{% include archive-year-month.html %}
    END
  end

end

class Site
  def initialize
    @options = Jekyll.configuration({})
    @site = Jekyll::Site.new(@options)
    @site.read_directories
  end
  
  def categories
    @site.categories
  end
end

def rebuild_file(name)
  puts "rebuilding #{name}"
  site = Site.new
  File.open(name, 'w+') do |file|
    file.puts yield(site.categories)
  end
end


def categories_content(categories)
  content = "<ul>\n"
  categories.sort.each do |category, post|
    content += "  <li><a href=\"/blog/#{category}/\" title=\"Zobacz wszystkie posty w kategorii #{category}\">#{category} ({{ site.categories.#{category}.size }})</a></li>\n" unless category =~ /^#{ROOT}/
  end
  content += "</ul>\n"
end

def rebuild_categories
  rebuild_file(CATEGORIES) do |categories|
    categories_content(categories)
  end
end

def sitemap_content(categories)
  content = <<-END
---
layout: nil
---
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  
  <!-- Blog/About -->
  <url> 
    <loc>http://michalorman.pl/</loc>
    <changefreq>daily</changefreq> 
    <priority>1</priority> 
  </url>
  <url> 
    <loc>http://michalorman.pl/blog/</loc>
    <changefreq>daily</changefreq> 
    <priority>1</priority> 
  </url>
  <url> 
    <loc>http://michalorman.pl/blog/o-blogu/</loc>
    <changefreq>monthly</changefreq> 
    <priority>0.8</priority> 
  </url>
  <url> 
    <loc>http://michalorman.pl/blog/o-mnie/</loc>
    <changefreq>monthly</changefreq> 
    <priority>0.8</priority> 
  </url>
  <url> 
    <loc>http://michalorman.pl/blog/o-mnie/neosoft/</loc>
    <changefreq>monthly</changefreq> 
    <priority>0.8</priority> 
  </url>
  <url> 
    <loc>http://michalorman.pl/blog/o-mnie/moje-projekty/</loc>
    <changefreq>monthly</changefreq> 
    <priority>0.8</priority> 
  </url>
  
  <!-- Archives -->
  END
  
  Dir["#{ROOT}/[0-9]*"].sort.each do |year|
    if (File.directory?(year))
      content += <<-END
  <url>
    <loc>http://michalorman.pl/#{year}/</loc>
    <changefreq>weekly</changefreq> 
    <priority>0.4</priority>
  </url>
      END
      Dir["#{year}/[0-9]*"].sort.each do |month|
        if (File.directory?(month))
          content += <<-END
  <url>
    <loc>http://michalorman.pl/#{month}/</loc>
    <changefreq>weekly</changefreq> 
    <priority>0.4</priority>
  </url>
          END
        end
      end
    end
  end
  
  content += "\n  <!-- Categories -->\n"
  
  categories.sort.each do |category, post|
    content += <<-END
  <url> 
    <loc>http://michalorman.pl/blog/#{category}/</loc>
    <changefreq>weekly</changefreq> 
    <priority>0.7</priority> 
  </url>
    END
  end
  
  content += <<-END
  
    <!-- Entries -->
{% for page in site.posts %}  <url>
    <loc>http://michalorman.pl{{ page.url }}/</loc>
    <lastmod>{{ page.date | date: "%Y-%m-%d" }}</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.9</priority> 
  </url>
{% endfor %}</urlset>
  END
end


def rebuild_sitemap
  rebuild_file(SITEMAP) do |categories|
    sitemap_content(categories)
  end
end

desc 'Create new category'
task :create_category, :name do |t, args|
  category = Category.new(args.name)
  category.create
  rebuild_categories
  rebuild_sitemap
end

task :rebuild_categories do
  rebuild_categories
end

desc 'Create new post'
task :create_post, :name, :category do |t, args|
  post = Post.new(args.name, args.category)
  post.create
  rebuild_categories
  rebuild_sitemap
end

desc 'Create archive'
task :create_archive, :month, :year do |t, args|
  archive = Archive.new(args.month, args.year)
  archive.create
end

task :rebuild_sitemap do |t|
  rebuild_sitemap
end
